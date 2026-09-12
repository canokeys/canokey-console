import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/views/applets/settings/settings_page.dart';
import 'package:canokey_console/views/applets/settings/widgets/action_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _SettingsController extends SettingsController {
  @override
  void onReady() {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    Get.testMode = true;
    PackageInfo.setMockInitialValues(
      appName: 'CanoKey',
      packageName: 'org.canokeys.console',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });
  tearDown(Get.reset);

  testWidgets('settings adapt to desktop, mobile, dark mode and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Get.put<SettingsController>(
      _SettingsController()
        ..polled = true
        ..key = ScreenshotMode.canoKey(),
    );
    for (final (size, dark, scale) in [
      (const Size(1536, 1200), false, 1.0),
      (const Size(390, 844), false, 1.0),
      (const Size(390, 844), true, 1.0),
      (const Size(320, 844), false, 2.0),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(dark: dark, scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final info = tester.getRect(find.byType(InfoCard));
      final actions = tester.getRect(find.byType(ActionCard));
      if (size.width > 1000) {
        expect(actions.top, info.top);
        expect(actions.left, greaterThan(info.right));
      } else {
        expect(actions.top, greaterThan(info.bottom));
      }
      expect(find.text('CanoKey Canary'), findsOneWidget);
      expect(find.text('230A454D4D313633202018694B'), findsOneWidget);
      await tester.ensureVisible(find.text('Reset CanoKey'));
      await tester.pumpAndSettle();
      expect(find.text('Reset CanoKey').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('device settings still open their dialogs', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1536, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Get.put<SettingsController>(
      _SettingsController()
        ..polled = true
        ..key = ScreenshotMode.canoKey(),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('LED'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disconnected settings retain local preferences and recovery', (
    tester,
  ) async {
    Get.put<SettingsController>(_SettingsController());
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(InfoCard), findsNothing);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Reset CanoKey'), findsOneWidget);
    expect(find.text('Reset PIV'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({bool dark = false, double scale = 1}) => GetMaterialApp(
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
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: const SettingsPage(),
);
