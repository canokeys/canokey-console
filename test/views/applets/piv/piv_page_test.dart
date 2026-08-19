import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('waits for a card without polling on page open', (tester) async {
    final controller = _TestPivController();
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(controller.refreshCount, 0);
    expect(find.byType(PollCanoKeyScreen), findsOneWidget);
    expect(
      find.text('Please read your CanoKey by clicking the refresh button'),
      findsNothing,
    );
    expect(find.byTooltip('PIV Algorithm IDs'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await Get.delete<PivController>(force: true);
  });

  testWidgets('does not expose X25519 shared-secret derivation',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..slots[0x9D] = _slot(0x9D, AlgorithmType.x25519);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final keyManagementSlot = find.text('Key Management - 9D');
    await tester.ensureVisible(keyManagementSlot);
    await tester.tap(keyManagementSlot);
    await tester.pumpAndSettle();

    expect(find.text('Derive Secret'), findsNothing);
    expect(find.text('Export Public Key'), findsOneWidget);
  });

  testWidgets('offers message signing without immediate verification',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final signatureSlot = find.text('Digital Signature - 9C');
    await tester.ensureVisible(signatureSlot);
    await tester.tap(signatureSlot);
    await tester.pumpAndSettle();

    expect(find.text('Sign Message'), findsOneWidget);
    expect(find.text('Sign File'), findsOneWidget);
    expect(find.text('Sign / Verify'), findsNothing);
  });
}

SlotInfo _slot(int number, AlgorithmType algorithm) => SlotInfo(
      number,
      algorithm,
      PinPolicy.once,
      TouchPolicy.never,
      Origin.generated,
      const [],
      false,
      0,
      0,
    );

class _TestPivController extends PivController {
  int refreshCount = 0;

  @override
  void onReady() {}

  @override
  Future<void> doRefreshData() async {
    refreshCount++;
  }
}

Widget _app() {
  return GetMaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: const PivPage(),
  );
}
