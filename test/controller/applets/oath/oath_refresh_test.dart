import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_controller/timer_controller.dart';

class _SessionController extends OathController {
  final sessions = CardSessions();
  int refreshCount = 0;

  @override
  Future<void> doRefreshData() => sessions.run((_) async {
    refreshCount++;
    // Match production: each successful card read starts the next countdown
    // within its session. Use a short period to exercise multiple expiries.
    timerController.reset();
    timerController.value = const TimerValue(
      remaining: 1,
      unit: TimerUnit.second,
    );
    timerController.start();
  });
}

void main() {
  testWidgets('expiry opens a fresh card session for every TOTP period', (
    tester,
  ) async {
    final previousConnection = SmartCard.connectionType;
    final previousNfcState = SmartCard.nfcState;
    SmartCard.connectionType = ConnectionType.ccid;
    final controller = _SessionController();
    try {
      controller.onReady();
      await tester.pump();
      expect(controller.refreshCount, 1);

      for (var period = 1; period <= 3; period++) {
        await tester.pump(const Duration(seconds: 1));
        expect(controller.refreshCount, period + 1);
        expect(controller.timerController.value.status, TimerStatus.running);
        expect(tester.takeException(), isNull);
      }
    } finally {
      controller.onClose();
      SmartCard.connectionType = previousConnection;
      SmartCard.nfcState = previousNfcState;
    }
  });
}
