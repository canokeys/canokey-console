@Tags(['native'])
library;

import 'dart:async';
import 'dart:convert';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Client extends PivCardClient {
  int slot = 0x9A;
  @override
  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions({
    String? managementKey,
    AlgorithmType managementKeyAlgorithm = AlgorithmType.tdes,
  }) async => null;
  @override
  Future<Uint8List> readMetadataDirectory() async =>
      Uint8List.fromList([1, 1, 1, 2, 6, slot, 3, 0x11, 1, 2, 1]);
  int preparations = 0, mutations = 0, authentications = 0, objectWrites = 0;
  bool interrupted = true;
  Uint8List protected = Uint8List.fromList([
    0x88,
    26,
    0x89,
    24,
    ...List.filled(24, 1),
  ]);
  @override
  Future<void> prepare() async {
    preparations++;
  }

  @override
  Future<bool> verifyPin(String pin) async => true;
  @override
  Future<bool> authenticateManagementKey(
    String key,
    AlgorithmType algorithm,
  ) async {
    authentications++;
    return true;
  }

  @override
  Future<void> setManagementKey({
    required int algorithm,
    required Uint8List key,
    int touch = 0,
    bool updateProtected = false,
  }) async {
    mutations++;
  }

  @override
  Future<Uint8List?> readObject(int id) async => id == 0x5fc109
      ? Uint8List.fromList(protected)
      : Uint8List.fromList([0x80, 3, 0x81, 1, 3]);
  @override
  Future<void> writeObject(int id, Uint8List data) async {
    objectWrites++;
    if (interrupted) throw PlatformException(code: '500');
    protected = Uint8List.fromList(data);
  }

  @override
  Future<SlotInfo?> readMetadata(int reference) async => SlotInfo(
    reference,
    AlgorithmType.aes192,
    PinPolicy.once,
    TouchPolicy.never,
    Origin.generated,
    [],
    false,
    3,
    3,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('continuation binds to the original card on $platform', (
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
          localizationsDelegates: const [S.delegate],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(audio, null);
        SmartCard.connectionType = ConnectionType.none;
        SmartCard.nfcState = NfcState.mute;
        Prompts.stopPromptAndroidPolling();
        Prompts.dismissTransientPrompt();
        Get.reset();
      });
      final polls = <Completer<String>>[];
      var serial = '01020304';
      messenger.setMockMethodCallHandler(audio, (_) async => null);
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'poll':
            final tag = Completer<String>();
            polls.add(tag);
            return tag.future;
          case 'transceive':
            final command = (call.arguments as Map)['data'] as String;
            return command.startsWith('0032') ? '${serial}9000' : '9000';
          case 'finish':
            return null;
        }
        throw StateError('Unexpected ${call.method}');
      });
      if (platform == TargetPlatform.android) {
        unawaited(SmartCard.startAndroidNfcHandler());
        await tester.pump();
      }
      Future<T> scan<T>(Future<T> action) async {
        await tester.pump();
        polls.last.complete(
          jsonEncode({'type': 'iso7816', 'id': '00', 'standard': 'ISO 14443'}),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final result = await action;
        await tester.pump(const Duration(milliseconds: 100));
        return result;
      }

      final client = _Client();
      final controller =
          PivController(
              client: client,
              readAppletStatus: () async => AppletSwitchStatus.fromConfig(
                firmwareVersion: const FirmwareVersion(3, 1, 1),
                functionSetVersion: FunctionSetVersion.v5,
                config: [0, 0, 0, 0, 0, 0xff],
              ),
            )
            ..firmwareVersion = const FirmwareVersion(3, 1, 1)
            ..functionSetVersion = FunctionSetVersion.v5
            ..pinOnlyMode = true;
      await scan(controller.refreshData());
      expect(controller.slots.keys, [0x9A]);
      expect(
        await scan(
          controller.changeManagementKey(
            '',
            '02' * 24,
            pin: '123456',
            usePinOnly: true,
            storeOnDevice: true,
          ),
        ),
        PivManagementKeyChangeResult.keyChangedProtectionIncomplete,
      );

      final before = (
        client.preparations,
        client.authentications,
        client.objectWrites,
      );
      serial = '05060708';
      client.slot = 0x9C;
      await scan(controller.refreshData());
      expect(controller.slots.keys, [
        0x9A,
      ], reason: 'Another card must not replace the pending card snapshot');
      expect(
        await scan(controller.continueManagementKeyChange('123456')),
        PivManagementKeyChangeResult.cardStateChanged,
      );
      expect(
        (client.preparations, client.authentications, client.objectWrites),
        before,
        reason:
            'Reject another card before applet reads, credentials or writes',
      );
      serial = '01020304';
      client.interrupted = false;
      expect(
        await scan(controller.continueManagementKeyChange('123456')),
        PivManagementKeyChangeResult.success,
      );
      expect(
        controller.slots.keys,
        [0x9A],
        reason:
            'Continuation returned to original card, but page must not show the other card snapshot',
      );
      expect(controller.polled, isTrue);
      expect(controller.dataRefreshFailed, isFalse);
      expect(client.mutations, 1);
      expect(controller.hasPendingManagementKeyChange, isFalse);
      expect(Prompts.cardReadPhase.value, isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }
}
