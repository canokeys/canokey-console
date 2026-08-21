import 'dart:typed_data';

import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
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
    tester.widget<PivSlotListItem>(_slotItem('9D')).onTap();
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
    tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
    await tester.pumpAndSettle();

    expect(find.text('Sign Message'), findsOneWidget);
    expect(find.text('Sign File'), findsOneWidget);
    expect(find.text('Sign / Verify'), findsNothing);
  });

  testWidgets('marks provisioning actions dangerous when slot has a key',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..slots[0x9A] = _slot(0x9A, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9A')).onTap();
    await tester.pumpAndSettle();

    for (final label in ['Generate CSR', 'Self-sign', 'Import']) {
      expect(_actionButton(tester, label).backgroundColor,
          AdminTheme.theme.contentTheme.danger);
    }
  });

  testWidgets(
      'marks provisioning actions dangerous when slot only has a certificate',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..certificateBytes[0x9A] = Uint8List.fromList([1]);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9A')).onTap();
    await tester.pumpAndSettle();

    expect(_actionButton(tester, 'Import').backgroundColor,
        AdminTheme.theme.contentTheme.danger);
  });

  testWidgets('limits ML-KEM slots to compatible management actions',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..extendedRetiredSlots = true
      ..slots[0x9D] = _slot(0x9D, AlgorithmType.mlkem768);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9D')).onTap();
    await tester.pumpAndSettle();

    expect(find.text('Generate Key'), findsOneWidget);
    expect(find.text('Export Public Key'), findsOneWidget);
    expect(find.text('Generate CSR'), findsNothing);
    expect(find.text('Self-sign'), findsNothing);
    expect(find.text('Sign Message'), findsNothing);
    expect(find.text('Download Attestation'), findsNothing);
  });

  testWidgets(
      'offers ML-DSA self-signing and attestation but not standalone generation',
      (tester) async {
    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..extendedRetiredSlots = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.mldsa65);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
    await tester.pumpAndSettle();

    expect(find.text('Self-sign'), findsOneWidget);
    expect(find.text('Generate CSR'), findsNothing);
    expect(find.text('Download Attestation'), findsOneWidget);
    await tester.tap(find.text('Generate Key'));
    await tester.pumpAndSettle();

    final algorithmDropdown = tester.widget<DropdownButton<AlgorithmType>>(
      find.byWidgetPredicate(
          (widget) => widget is DropdownButton<AlgorithmType>),
    );
    expect(
      algorithmDropdown.items!.map((item) => item.value),
      [AlgorithmType.mlkem768],
    );
  });
}

Finder _slotItem(String slotNumber) {
  return find.byWidgetPredicate(
    (widget) => widget is PivSlotListItem && widget.slotNumber == slotNumber,
  );
}

CustomizedButton _actionButton(WidgetTester tester, String label) {
  return tester.widget<CustomizedButton>(find.ancestor(
    of: find.text(label),
    matching: find.byType(CustomizedButton),
  ));
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
