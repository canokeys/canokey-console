@Tags(['native'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('one NFC scan owns all sequence steps on $platform', (
      tester,
    ) async {
      const channel = MethodChannel('flutter_nfc_kit/method');
      const audio = MethodChannel('org.canokeys.console/audio');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Get.testMode = true;
      SmartCard.connectionType = ConnectionType.none;
      SmartCard.nfcState = NfcState.idle;
      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(audio, null);
        SmartCard.connectionType = ConnectionType.none;
        SmartCard.nfcState = NfcState.mute;
        Get.reset();
      });

      final polls = <Completer<String>>[];
      final commands = <String>[];
      var finishes = 0;
      messenger.setMockMethodCallHandler(audio, (_) async => null);
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'poll':
            final tag = Completer<String>();
            polls.add(tag);
            return tag.future;
          case 'transceive':
            final command = (call.arguments as Map)['data'] as String;
            commands.add(command);
            return command.startsWith('0032') ? '010203049000' : '9000';
          case 'finish':
            finishes++;
            return null;
        }
        throw StateError('Unexpected ${call.method}');
      });
      if (platform == TargetPlatform.android) {
        unawaited(SmartCard.startAndroidNfcHandler());
        await tester.pump();
      }

      final serials = <String>[];
      final leases = <CardLease>[];
      final firstStep = Completer<void>();
      final continueSteps = Completer<void>();
      final sequence = SmartCard.processSequence(() async {
        for (var step = 0; step < 3; step++) {
          await SmartCard.process((sn) async {
            serials.add(sn);
            leases.add(SmartCard.currentLease);
            await SmartCard.transceive('00CA000000');
          });
          if (step == 0) {
            firstStep.complete();
            await continueSteps.future;
          }
        }
        return 'done';
      });
      await tester.pump();
      polls.single.complete(
        jsonEncode({'type': 'iso7816', 'id': '00', 'standard': 'ISO 14443'}),
      );
      await tester.pump();
      await firstStep.future;
      await tester.pump(const Duration(seconds: 1));
      expect(
        polls,
        hasLength(1),
        reason: 'Do not restart reader mode between steps',
      );
      expect(finishes, 0);
      continueSteps.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(await sequence, 'done');
      expect(serials, ['01020304', '01020304', '01020304']);
      expect(leases, hasLength(3));
      expect(leases.every((lease) => identical(lease, leases.first)), isTrue);
      expect(leases.first.check, throwsStateError);
      expect(commands.where((c) => c.startsWith('0032')), hasLength(1));
      expect(commands.where((c) => c.startsWith('00CA')), hasLength(3));
      expect(finishes, platform == TargetPlatform.iOS ? 1 : 0);
      // Let Android resume its one background poll, then leave it pending.
      await tester.pump(const Duration(milliseconds: 100));
    }, variant: TargetPlatformVariant.only(platform));
  }
}
