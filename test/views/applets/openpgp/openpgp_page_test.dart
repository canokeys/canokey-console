import 'package:canokey_console/controller/applets/openpgp/openpgp_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/change_pin_dialog.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/openpgp_page.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_card_info_card.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_pin_management_card.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_touch_policy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Controller extends OpenPgpController {
  @override
  void onReady() {}
}

OpenPgpCardInfo _info({int retries = 3}) => OpenPgpCardInfo(
  version: '3.4',
  manufacturer: 'CanoKey',
  serialNumber: 'FFFFFFFF',
  cardHolder: 'Card holder',
  publicKeyUrl: 'https://example.com/public-key.asc',
  pinState: OpenPgpPinState(
    signaturePinForced: false,
    userRetries: retries,
    resetRetries: 3,
    adminRetries: 3,
  ),
  keySlots: {
    for (final type in OpenPgpKeyType.values)
      type: OpenPgpKeySlotInfo(
        type: type,
        fingerprint: '0123456789ABCDEF0123456789ABCDEF01234567',
        generatedAt: null,
        touchPolicy: type == OpenPgpKeyType.signature
            ? OpenPgpTouchPolicy.permanent
            : OpenPgpTouchPolicy.off,
        touchFixed: type == OpenPgpKeyType.signature,
      ),
  },
  touchCacheTime: 15,
);

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('page adapts to desktop, mobile, dark mode and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Get.put<OpenPgpController>(
      _Controller()
        ..polled = true
        ..cardInfo = _info()
        ..supportsPinRetryConfig = true,
    );
    for (final (size, dark, scale) in [
      (const Size(1536, 1400), false, 1.0),
      (const Size(390, 1000), true, 1.0),
      (const Size(320, 1000), false, 2.0),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(const OpenPgpPage(), dark: dark, scale: scale),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final info = tester.getRect(find.byType(OpenPgpCardInfoCard));
      final pins = tester.getRect(find.byType(OpenPgpPinManagementCard));
      if (size.width > 1000) {
        expect(pins.top, info.top);
        expect(pins.left, greaterThan(info.right));
      } else {
        expect(pins.top, greaterThan(info.bottom));
      }
      await tester.ensureVisible(find.text(S.current.changePin));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.changePin));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePinDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      Get.back();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('PIN recovery and retry configuration follow device state', (
    tester,
  ) async {
    final controller = _Controller()
      ..polled = true
      ..cardInfo = _info();
    Get.put<OpenPgpController>(controller);
    await tester.pumpWidget(_app(const OpenPgpPage()));
    await tester.pumpAndSettle();
    TextButton recovery() => tester.widget<TextButton>(
      find.ancestor(
        of: find.text(S.current.openpgpUnblockUserPin),
        matching: find.byType(TextButton),
      ),
    );
    expect(recovery().onPressed, isNull);
    expect(find.text(S.current.openpgpSetPinRetries), findsNothing);
    controller.cardInfo = _info(retries: 0);
    controller.supportsPinRetryConfig = true;
    controller.update();
    await tester.pumpAndSettle();
    expect(recovery().onPressed, isNotNull);
    expect(find.text(S.current.openpgpSetPinRetries), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixed touch policies stay non-interactive', (tester) async {
    final changed = <OpenPgpKeyType>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: OpenPgpTouchPolicyCard(
            info: _info(),
            onChange: (slot) => changed.add(slot.type),
            onChangeCacheTime: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(OpenPgpKeyType.signature.label));
    expect(changed, isEmpty);
    await tester.tap(find.text(OpenPgpKeyType.encryption.label));
    expect(changed, [OpenPgpKeyType.encryption]);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {bool dark = false, double scale = 1}) =>
    GetMaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );
