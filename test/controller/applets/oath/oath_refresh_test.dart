import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_controller/timer_controller.dart';

class _OathClient extends OathCardClient {
  final challenges = <int>[];

  @override
  Future<void> prepare() async {}

  @override
  Future<OathSelection> select() async =>
      const OathSelection(version: OathVersion.v1, requiresCode: false);

  @override
  Future<List<OathCalculatedEntry>> calculateAll(
    String challengeHex, {
    Uint8List? key,
  }) async {
    final challenge = int.parse(challengeHex, radix: 16);
    challenges.add(challenge);
    return [_TotpEntry(challenge)];
  }
}

class _TotpEntry implements OathCalculatedEntry {
  const _TotpEntry(this.rawCode);

  @override
  final int rawCode;
  @override
  String get name => 'TOTP';
  @override
  int get digits => 6;
  @override
  bool get isHotp => false;
  @override
  bool get requiresTouch => false;
}

Future<void> _setLifecycle(WidgetTester tester, AppLifecycleState state) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.lifecycle.name,
    SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
    (_) {},
  );
}

void main() {
  testWidgets('expiry opens a fresh card session for every TOTP period', (
    tester,
  ) async {
    final previousConnection = SmartCard.connectionType;
    final previousNfcState = SmartCard.nfcState;
    SmartCard.connectionType = ConnectionType.ccid;
    var now = DateTime.fromMillisecondsSinceEpoch(59 * 1000);
    final client = _OathClient();
    final controller = OathController(client: client, now: () => now);
    try {
      await _setLifecycle(tester, AppLifecycleState.resumed);
      controller.onReady();
      await tester.pump();
      expect(client.challenges, [1]);

      for (final (delay, challenge) in [(1, 2), (30, 3), (30, 4)]) {
        now = now.add(Duration(seconds: delay));
        await tester.pump(Duration(seconds: delay));
        expect(client.challenges.last, challenge);
        expect(controller.timerController.value.status, TimerStatus.running);
        expect(tester.takeException(), isNull);
      }
      expect(client.challenges, [1, 2, 3, 4]);
    } finally {
      controller.onClose();
      SmartCard.connectionType = previousConnection;
      SmartCard.nfcState = previousNfcState;
    }
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name} USB TOTP resyncs to wall time on resume', (
      tester,
    ) async {
      final previousConnection = SmartCard.connectionType;
      final previousNfcState = SmartCard.nfcState;
      debugDefaultTargetPlatformOverride = platform;
      SmartCard.connectionType = ConnectionType.ccid;
      var now = DateTime.fromMillisecondsSinceEpoch(31 * 1000);
      final client = _OathClient();
      final controller = OathController(client: client, now: () => now);
      try {
        await _setLifecycle(tester, AppLifecycleState.resumed);
        controller.onReady();
        await tester.pump();
        expect(client.challenges, [1]);
        expect(controller.oathMap['TOTP']!.code, '000001');
        expect(controller.timerController.value.remaining, 29);

        await _setLifecycle(tester, AppLifecycleState.paused);
        // Advance wall time without running any countdown callbacks.
        now = now.add(const Duration(seconds: 20));
        await _setLifecycle(tester, AppLifecycleState.resumed);
        expect(client.challenges, [1]);
        expect(controller.oathMap['TOTP']!.code, '000001');
        expect(controller.timerController.value.remaining, 9);

        await _setLifecycle(tester, AppLifecycleState.paused);
        now = now.add(const Duration(seconds: 40));
        await _setLifecycle(tester, AppLifecycleState.resumed);
        await tester.pump();
        expect(client.challenges, [1, 3]);
        expect(controller.oathMap['TOTP']!.code, '000003');
        expect(controller.timerController.value.remaining, 29);
      } finally {
        controller.onClose();
        SmartCard.connectionType = previousConnection;
        SmartCard.nfcState = previousNfcState;
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('${platform.name} NFC clears expired TOTP on resume', (
      tester,
    ) async {
      final previousConnection = SmartCard.connectionType;
      final previousNfcState = SmartCard.nfcState;
      debugDefaultTargetPlatformOverride = platform;
      SmartCard.connectionType = ConnectionType.ccid;
      var now = DateTime.fromMillisecondsSinceEpoch(59 * 1000);
      final controller = OathController(client: _OathClient(), now: () => now);
      final nfcCalls = <String>[];
      const nfc = MethodChannel('flutter_nfc_kit/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(nfc, (
        call,
      ) async {
        nfcCalls.add(call.method);
        return null;
      });
      try {
        await _setLifecycle(tester, AppLifecycleState.resumed);
        controller.onReady();
        await tester.pump();
        // Reuse the loaded credentials while switching to the NFC path.
        SmartCard.connectionType = ConnectionType.nfc;
        SmartCard.nfcState = NfcState.idle;
        final touch = OathItem('', 'Touch', requireTouch: true, code: '112233');
        final hotp = OathItem(
          '',
          'HOTP',
          type: OathType.hotp,
          requireTouch: true,
          code: '123456',
        );
        controller.oathMap.addAll({touch.name: touch, hotp.name: hotp});
        expect(controller.oathMap['TOTP']!.code, '000001');
        await _setLifecycle(tester, AppLifecycleState.paused);
        now = now.add(const Duration(seconds: 1));
        await _setLifecycle(tester, AppLifecycleState.resumed);
        await tester.pump();
        expect(controller.oathMap['TOTP']!.code, isEmpty);
        expect(touch.code, isEmpty);
        expect(hotp.code, '123456');
        expect(nfcCalls, isEmpty);
        expect(SmartCard.nfcState, NfcState.idle);
      } finally {
        controller.onClose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          nfc,
          null,
        );
        SmartCard.connectionType = previousConnection;
        SmartCard.nfcState = previousNfcState;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
