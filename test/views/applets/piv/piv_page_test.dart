import 'package:canokey_console/views/applets/piv/widgets/piv_surface.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/piv_macos_setup.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'dart:typed_data';

import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
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

  // Expectations deliberately do not use controller capability getters.
  for (final (version, modern, extensions) in [
    ('1.6.2', false, false),
    ('2.0.1', false, true),
    ('3.0.3', false, true),
    ('3.1.0-28-gd2820836', true, true),
    ('3.1.0', true, true),
    ('3.1.1', true, true),
  ]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets(
        'PIV $version exposes compatible actions and algorithms at $width',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 1000);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final controller = _TestPivController()
            ..polled = true
            ..slots[0x9A] = _slot(0x9A, AlgorithmType.eccp256);
          _setFirmware(controller, version);
          Get.put<PivController>(controller);
          await tester.pumpWidget(_app(theme: AppTheme.lightTheme));
          await tester.pumpAndSettle();

          expect(
            find.text(S.current.pivManagementKeyAuthentication),
            modern ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(S.current.pivSetPinPukRetries),
            modern ? findsOneWidget : findsNothing,
          );
          if (modern) {
            expect(
              _actionButton(tester, S.current.pivSetPinPukRetries).onPressed,
              isNotNull,
            );
          }
          await tester.ensureVisible(_slotItem('9A'));
          await tester.tap(_slotItem('9A'));
          await tester.pumpAndSettle();
          expect(
            find.text(S.current.pivClearSlot),
            modern ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(S.current.pivGenerateKey),
            modern ? findsOneWidget : findsNothing,
          );
          await tester.ensureVisible(find.text(S.current.pivSelfSign));
          await tester.tap(find.text(S.current.pivSelfSign));
          await tester.pumpAndSettle();

          final credentials = find.byType(TextFormField);
          await tester.enterText(credentials.at(0), '123456');
          await tester.enterText(
            credentials.at(1),
            '010203040506070801020304050607080102030405060708',
          );
          await tester.ensureVisible(find.text(S.current.next));
          await tester.pumpAndSettle();
          await tester.tap(find.text(S.current.next));
          await tester.pumpAndSettle();
          final dropdown = find.byWidgetPredicate(
            (widget) => widget is DropdownButton<AlgorithmType>,
          );
          final expected = [
            AlgorithmType.eccp256,
            AlgorithmType.eccp384,
            if (modern) AlgorithmType.eccp521,
            if (extensions) ...[
              AlgorithmType.secp256k1,
              AlgorithmType.sm2,
              AlgorithmType.ed25519,
            ],
            if (modern) AlgorithmType.mldsa65,
            AlgorithmType.rsa2048,
            if (extensions) ...[AlgorithmType.rsa3072, AlgorithmType.rsa4096],
          ];
          expect(
            tester
                .widget<DropdownButton<AlgorithmType>>(dropdown)
                .items!
                .map((item) => item.value),
            expected,
          );
          await tester.ensureVisible(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          expect(find.text(AlgorithmType.rsa2048.label), findsWidgets);
          expect(
            find.text(AlgorithmType.mldsa65.label),
            modern ? findsWidgets : findsNothing,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('PIV updates firmware actions without recreating the page', (
    tester,
  ) async {
    final controller = _TestPivController()..polled = true;
    _setFirmware(controller, '3.1.1');
    Get.put<PivController>(controller);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final (version, modern) in [
      ('3.1.1', true),
      ('1.6.2', false),
      ('3.0.3', false),
      ('3.1.1', true),
    ]) {
      _setFirmware(controller, version);
      controller.update();
      await tester.pumpAndSettle();
      expect(
        find.text(S.current.pivManagementKeyAuthentication),
        modern ? findsOneWidget : findsNothing,
        reason: version,
      );
      expect(
        find.text(S.current.pivSetPinPukRetries),
        modern ? findsOneWidget : findsNothing,
        reason: version,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('PIV surfaces fit desktop and mobile with the app theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..extendedRetiredSlots = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.rsa3072);
    Get.put<PivController>(controller);
    for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(theme: AppTheme.lightTheme));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Sign Message'));
      expect(find.text('Sign Message').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
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

  testWidgets('legacy PIN-only cards retain recovery while PUK is usable', (
    tester,
  ) async {
    final controller = _TestPivController()
      ..polled = true
      ..pinOnlyMode = true
      ..pinInfo = SlotInfo(
        0x80,
        AlgorithmType.pin,
        PinPolicy.once,
        TouchPolicy.never,
        Origin.generated,
        const [],
        false,
        3,
        0,
      )
      ..pukInfo = SlotInfo(
        0x81,
        AlgorithmType.pin,
        PinPolicy.once,
        TouchPolicy.never,
        Origin.generated,
        const [],
        false,
        3,
        3,
      );
    Get.put<PivController>(controller);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_actionButton(tester, S.current.pivUnblockPin).onPressed, isNotNull);

    controller.pukInfo = SlotInfo(
      0x81,
      AlgorithmType.pin,
      PinPolicy.once,
      TouchPolicy.never,
      Origin.generated,
      const [],
      false,
      3,
      0,
    );
    controller.update();
    await tester.pumpAndSettle();
    expect(_actionButton(tester, S.current.pivUnblockPin).onPressed, isNull);
  });

  testWidgets('does not expose X25519 shared-secret derivation', (
    tester,
  ) async {
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

  testWidgets('slot details provide an explicit close action', (tester) async {
    final controller = _TestPivController()..polled = true;
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9A')).onTap();
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('slot actions expose a scrollable key operations section', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..extendedRetiredSlots = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
    await tester.pumpAndSettle();

    expect(find.text('Key operations'), findsOneWidget);

    final dialog = find.byType(Dialog);
    final scrollbarFinder = find.descendant(
      of: dialog,
      matching: find.byType(Scrollbar),
    );
    expect(scrollbarFinder, findsOneWidget);

    final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
    expect(scrollbar.controller!.position.maxScrollExtent, greaterThan(0));

    final scrollView = find.descendant(
      of: dialog,
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(scrollView, const Offset(0, -160));
    await tester.pumpAndSettle();

    expect(scrollbar.controller!.position.pixels, greaterThan(0));
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('slot action groups flow into columns on wide layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2000, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..extendedRetiredSlots = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
    await tester.pumpAndSettle();

    final provisioningTop = tester.getTopLeft(find.text('Provisioning')).dy;
    final exportTop = tester.getTopLeft(find.text('Export')).dy;
    final operationsTop = tester.getTopLeft(find.text('Key operations')).dy;

    expect(exportTop, provisioningTop);
    expect(operationsTop, provisioningTop);
    Finder action(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(PivButton));
    final buttons = [
      'Generate CSR',
      'Export Public Key',
      'Sign Message',
      'Clear Slot',
    ].map(action).toList();
    final firstTop = tester.getTopLeft(buttons.first).dy;
    final firstHeight = tester.getSize(buttons.first).height;
    for (final button in buttons) {
      expect(tester.getTopLeft(button).dy, firstTop);
      expect(tester.getSize(button).height, firstHeight);
    }
    expect(
      tester.getSize(action('Generate CSR')),
      tester.getSize(action('Self-sign')),
    );
    expect(
      tester.getSize(action('Export Public Key')),
      tester.getSize(action('Download Attestation')),
    );
    expect(
      tester.getSize(action('Sign Message')),
      tester.getSize(action('Verify File')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers message signing without immediate verification', (
    tester,
  ) async {
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

  testWidgets('message signing dialog suspends page NFC refresh', (
    tester,
  ) async {
    SmartCard.nfcState = NfcState.idle;
    final controller = _TestPivController()
      ..polled = true
      ..slots[0x9C] = _slot(0x9C, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9C')).onTap();
    await tester.pumpAndSettle();
    expect(SmartCard.nfcState, NfcState.input);

    await tester.ensureVisible(find.text('Sign Message'));
    await tester.tap(find.text('Sign Message'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Message'), findsOneWidget);
    expect(SmartCard.nfcState, NfcState.input);

    final pinDecorator = find.byWidgetPredicate(
      (widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'PIN',
    );
    final pinField = tester.widget<EditableText>(
      find.descendant(of: pinDecorator, matching: find.byType(EditableText)),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is InputDecorator && widget.decoration.labelText == 'PIN',
      ),
      findsOneWidget,
    );
    expect(pinField.autofocus, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(SmartCard.nfcState, NfcState.idle);
  });

  for (final scenario in [
    (slot: '9A', algorithm: AlgorithmType.eccp256, keyUsage: 1),
    (slot: '9A', algorithm: AlgorithmType.rsa2048, keyUsage: 1),
    (slot: '9D', algorithm: AlgorithmType.eccp256, keyUsage: 16),
    (slot: '9D', algorithm: AlgorithmType.rsa2048, keyUsage: 4),
  ]) {
    testWidgets(
      'self-sign ${scenario.slot} ${scenario.algorithm.name} forwards its profile and guides to the other slot',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final otherSlot = scenario.slot == '9A' ? '9D' : '9A';
        final otherId = int.parse(otherSlot, radix: 16);
        final existingOtherKey = _slot(otherId, AlgorithmType.eccp256);
        final controller = _TestPivController()
          ..polled = true
          ..selfSignResult = Uint8List.fromList([0x30, 0x00])
          ..slots[otherId] = existingOtherKey;
        Get.put<PivController>(controller);
        await tester.pumpWidget(GlobalLoaderOverlay(child: _app()));
        await tester.pumpAndSettle();
        tester.widget<PivSlotListItem>(_slotItem(scenario.slot)).onTap();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Self-sign'));
        await tester.pumpAndSettle();
        final credentials = find.byType(TextFormField);
        await tester.enterText(credentials.at(0), '123456');
        await tester.enterText(
          credentials.at(1),
          '010203040506070801020304050607080102030405060708',
        );
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        tester
            .widget<DropdownButtonFormField<AlgorithmType>>(
              find.byType(DropdownButtonFormField<AlgorithmType>),
            )
            .onChanged!(scenario.algorithm);
        tester
            .widget<DropdownButtonFormField<PinPolicy>>(
              find.byType(DropdownButtonFormField<PinPolicy>),
            )
            .onChanged!(PinPolicy.once);
        tester
            .widget<DropdownButtonFormField<TouchPolicy>>(
              find.byType(DropdownButtonFormField<TouchPolicy>),
            )
            .onChanged!(TouchPolicy.always);
        await tester.pumpAndSettle();
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        expect(find.text(S.current.pivMacOsApply), findsNothing);
        expect(find.text(S.current.pivMacOsOtherSlot), findsNothing);
        final usage = {
          1: 'digitalSignature',
          4: 'keyEncipherment',
          16: 'keyAgreement',
        }[scenario.keyUsage]!;
        await tester.ensureVisible(find.text(usage));
        await tester.tap(find.text(usage));
        if (scenario.slot == '9A') {
          await tester.ensureVisible(find.text('clientAuth'));
          await tester.tap(find.text('clientAuth'));
        }
        await tester.ensureVisible(find.text(S.current.pivEndEntityConstraint));
        await tester.tap(find.text(S.current.pivEndEntityConstraint));
        await tester.pumpAndSettle();
        tester.widget<Stepper>(find.byType(Stepper)).onStepCancel!();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButton<AlgorithmType>>(
                find.byType(DropdownButton<AlgorithmType>),
              )
              .value,
          scenario.algorithm,
        );
        expect(
          tester
              .widget<DropdownButton<PinPolicy>>(
                find.byType(DropdownButton<PinPolicy>),
              )
              .value,
          PinPolicy.once,
        );
        expect(
          tester
              .widget<DropdownButton<TouchPolicy>>(
                find.byType(DropdownButton<TouchPolicy>),
              )
              .value,
          TouchPolicy.always,
        );
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        for (final entry in {
          S.current.pivCommonName: 'My Mac',
          S.current.pivDnsSans: 'example.com',
          S.current.pivValidityDays: '730',
        }.entries) {
          final field = find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == entry.key,
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, entry.value);
        }
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        expect(controller.selfSignArguments, isNull);
        expect(find.text(S.current.pivOverwriteKey), findsOneWidget);
        await tester.tap(find.text(S.current.pivOverwrite));
        await tester.pumpAndSettle();
        expect(controller.selfSignArguments, {
          'slot': scenario.slot,
          'algorithm': scenario.algorithm,
          'pinPolicy': PinPolicy.once,
          'touchPolicy': TouchPolicy.always,
          'subject': {'CN': 'My Mac'},
          'sans': ['example.com'],
          'validityDays': 730,
          'keyUsage': scenario.keyUsage,
          'keyUsageCritical': true,
          'extendedKeyUsage': scenario.slot == '9A'
              ? ['1.3.6.1.5.5.7.3.2']
              : <String>[],
          'includeBasicConstraints': true,
        });
        expect(
          find.text(
            scenario.slot == '9A'
                ? S.current.pivMacOsAfterAuthentication
                : S.current.pivMacOsAfterKeychain,
          ),
          findsOneWidget,
        );
        expect(controller.slots[otherId], same(existingOtherKey));
        final generation = controller.selfSignArguments;
        await tester.tap(find.text(S.current.pivMacOsCheckSlot(otherSlot)));
        await tester.pumpAndSettle();
        expect(controller.selfSignArguments, same(generation));
        expect(controller.slots[otherId], same(existingOtherKey));
        expect(find.byType(Stepper), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('uses consistent neutral styling for provisioning actions', (
    tester,
  ) async {
    final controller = _TestPivController()
      ..polled = true
      ..slots[0x9A] = _slot(0x9A, AlgorithmType.eccp256);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.widget<PivSlotListItem>(_slotItem('9A')).onTap();
    await tester.pumpAndSettle();

    for (final label in ['Generate CSR', 'Self-sign', 'Import']) {
      expect(
        tester
            .widget<PivButton>(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(PivButton),
              ),
            )
            .primary,
        isFalse,
      );
    }
  });

  testWidgets(
    'keeps import available as a secondary action for a certificate-only slot',
    (tester) async {
      final controller = _TestPivController()
        ..polled = true
        ..certificateBytes[0x9A] = Uint8List.fromList([1]);
      Get.put<PivController>(controller);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      tester.widget<PivSlotListItem>(_slotItem('9A')).onTap();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<PivButton>(
              find.ancestor(
                of: find.text('Import'),
                matching: find.byType(PivButton),
              ),
            )
            .primary,
        isFalse,
      );
    },
  );

  testWidgets('loads a certificate-only v5 slot when details are opened', (
    tester,
  ) async {
    final controller = _TestPivController()
      ..polled = true
      ..functionSetVersion = FunctionSetVersion.v5
      ..certificateSlots.add(0x9A);
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final item = tester.widget<PivSlotListItem>(_slotItem('9A'));
    expect(item.hasCertificate, isTrue);
    expect(controller.certificateBytes, isEmpty);

    item.onTap();
    await tester.pumpAndSettle();

    expect(controller.detailsLoadCount, 1);
    expect(controller.certificateBytes[0x9A], isNotNull);
    expect(find.text('Export Certificate'), findsOneWidget);
  });

  testWidgets('limits ML-KEM slots to compatible management actions', (
    tester,
  ) async {
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

      expect(controller.detailsLoadCount, 1);
      expect(find.text('Self-sign'), findsOneWidget);
      expect(find.text('Generate CSR'), findsNothing);
      expect(find.text('Download Attestation'), findsOneWidget);
      await tester.ensureVisible(find.text('Generate Key'));
      await tester.tap(find.text('Generate Key'));
      await tester.pumpAndSettle();

      final algorithmDropdown = tester.widget<DropdownButton<AlgorithmType>>(
        find.byWidgetPredicate(
          (widget) => widget is DropdownButton<AlgorithmType>,
        ),
      );
      expect(algorithmDropdown.items!.map((item) => item.value), [
        AlgorithmType.mlkem768,
      ]);
    },
  );
}

Finder _slotItem(String slotNumber) {
  return find.byWidgetPredicate(
    (widget) => widget is PivSlotListItem && widget.slotNumber == slotNumber,
  );
}

CustomizedButton _actionButton(WidgetTester tester, String label) {
  return tester.widget<CustomizedButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(CustomizedButton),
    ),
  );
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
  int detailsLoadCount = 0;

  Map<String, Object>? selfSignArguments;
  Uint8List? selfSignResult;

  @override
  Future<Uint8List?> generateSelfSignedCertificate(
    String slot,
    AlgorithmType algorithm,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
    String pin,
    String managementKey,
    Map<String, String> subject,
    List<String> subjectAlternativeNames,
    int validityDays,
    bool usePinOnly, {
    int keyUsage = 0,
    bool keyUsageCritical = true,
    List<String> extendedKeyUsage = const [],
    bool includeBasicConstraints = false,
    bool reuseExistingKey = false,
    PivMacOsSetupSlot? expectedState,
    String? expectedSerial,
  }) async {
    selfSignArguments = {
      'slot': slot,
      'algorithm': algorithm,
      'pinPolicy': pinPolicy,
      'touchPolicy': touchPolicy,
      'subject': subject,
      'sans': subjectAlternativeNames,
      'validityDays': validityDays,
      'keyUsage': keyUsage,
      'keyUsageCritical': keyUsageCritical,
      'extendedKeyUsage': extendedKeyUsage,
      'includeBasicConstraints': includeBasicConstraints,
    };
    return selfSignResult;
  }

  @override
  void onReady() {}

  @override
  Future<void> doRefreshData() async {
    refreshCount++;
  }

  @override
  Future<SlotInfo?> loadSlotDetails(int slot) async {
    detailsLoadCount++;
    if (certificateSlots.contains(slot)) {
      certificateBytes[slot] = Uint8List.fromList([1]);
    }
    return slots[slot];
  }
}

Widget _app({ThemeData? theme}) {
  return GetMaterialApp(
    theme: theme,
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

void _setFirmware(PivController controller, String version) {
  controller.firmwareVersion = FirmwareVersion.parse(version);
  controller.functionSetVersion = CanoKey.functionSetFromFirmwareVersion(
    version,
  );
  controller.algorithmExtensionConfig = version.startsWith('2.')
      ? PivAlgorithmExtensionConfig.legacyV2
      : PivAlgorithmExtensionConfig.defaults;
}
