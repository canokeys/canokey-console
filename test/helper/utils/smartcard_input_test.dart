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
    for (final mode in ['reject', 'lost', 'swap']) {
      testWidgets('input scan $mode releases and verifies card on $platform', (
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
        var serial = '01020304';
        var userCommands = 0;
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
              if (command == '00CA000000') {
                userCommands++;
                if (mode == 'lost' && userCommands == 1) {
                  throw PlatformException(code: '500', message: 'Tag lost');
                }
              }
              return command.startsWith('0032') ? '${serial}9000' : '9000';
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

        final ready = Completer<void>();
        final leases = <CardLease>[];
        var attempts = 0;
        final operation = SmartCard.processSequence(() async {
          await SmartCard.stopPollingNfc(withInput: true);
          ready.complete();
          final first = await SmartCard.withInputCard<bool>(
            '01020304',
            () async {
              attempts++;
              leases.add(SmartCard.currentLease);
              if (mode == 'lost') await SmartCard.transceive('00CA000000');
              return null;
            },
          );
          if (first != null) throw StateError('Expected rejected input');
          return SmartCard.withInputCard<bool>('01020304', () async {
            attempts++;
            leases.add(SmartCard.currentLease);
            if (mode == 'lost') await SmartCard.transceive('00CA000000');
            return true;
          });
        });
        final rejected = mode == 'swap'
            ? expectLater(operation, throwsStateError)
            : null;
        await tester.pump();
        String tag() => jsonEncode({
          'type': 'iso7816',
          'id': '00',
          'standard': 'ISO 14443',
        });
        polls.single.complete(tag());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));
        await ready.future;
        expect(polls, hasLength(2));
        if (mode == 'swap') serial = 'AABBCCDD';
        polls.last.complete(tag());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));
        if (mode == 'swap') {
          await tester.pump(const Duration(milliseconds: 500));
          await rejected;
          expect(
            attempts,
            0,
            reason: 'Do not send credentials to a swapped card',
          );
        } else {
          expect(
            polls,
            hasLength(3),
            reason: 'Failed input must release the Android reader gate',
          );
          polls.last.complete(tag());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(await operation, isTrue);
          expect(attempts, 2);
          expect(identical(leases[0], leases[1]), isFalse);
          expect(leases[0].check, throwsStateError);
          expect(leases[1].check, throwsStateError);
          expect(
            userCommands,
            mode == 'lost' ? 2 : 0,
            reason: 'No implicit APDU replay',
          );
        }
        expect(
          finishes,
          greaterThanOrEqualTo(platform == TargetPlatform.iOS ? 1 : 0),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }, variant: TargetPlatformVariant.only(platform));
    }
  }
}
