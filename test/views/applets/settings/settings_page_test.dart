import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/applet_switches_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/sm2_config_dialog.dart';
import 'package:canokey_console/views/applets/settings/settings_page.dart';
import 'package:canokey_console/views/applets/settings/widgets/action_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _SettingsController extends SettingsController {
  Map<Func, bool>? submittedSwitches;
  @override
  void onReady() {}
  @override
  Future<void> changeSwitches(Map<Func, bool> values) async {
    submittedSwitches = values;
  }
}

class _Sm2SettingsController extends SettingsController {
  int sm2Reads = 0;
  @override
  void onReady() {}
  @override
  Future<WebAuthnSm2Config?> readSm2Config() async {
    sm2Reads++;
    return const WebAuthnSm2Config(enabled: true, curveId: 9, algoId: -54);
  }
}

class _LifecycleSettingsController extends SettingsController {
  int refreshes = 0;
  @override
  Future<void> doRefreshData() async {
    refreshes++;
  }
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

  for (final firmware in ['1.0.0', '1.5.2', '1.6.2', '3.0.0']) {
    testWidgets('$firmware shows applet switches when NDEF is supported', (
      tester,
    ) async {
      Get.put<SettingsController>(
        _SettingsController()
          ..polled = true
          ..key = _legacyKey(firmware),
      );
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(
        find.text(S.current.settingsAppletSwitches),
        firmware == '1.0.0' ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final enabled in [true, false]) {
    testWidgets('1.6.2 can submit NDEF ${enabled ? 'disable' : 'enable'}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1536, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _SettingsController()
        ..polled = true
        ..key = _legacyKey('1.6.2', ndefEnabled: enabled);
      Get.put<SettingsController>(controller);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(S.current.settingsAppletSwitches));
      await tester.tap(find.text(S.current.settingsAppletSwitches));
      await tester.pumpAndSettle();
      final dialog = find.byType(AppletSwitchesDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('NFC Tag')),
        findsOneWidget,
      );
      final checkbox = find.descendant(
        of: dialog,
        matching: find.byType(Checkbox),
      );
      expect(checkbox, findsOneWidget);
      expect(tester.widget<Checkbox>(checkbox).value, enabled);
      await tester.tap(checkbox);
      await tester.pump();
      expect(controller.submittedSwitches, isNull);
      await tester.tap(find.text(S.current.save));
      await tester.pump();
      expect(controller.submittedSwitches, {Func.ndefEnabled: !enabled});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'web settings refresh on each page entry with a retained controller',
    (tester) async {
      final controller =
          Get.put<SettingsController>(
                _LifecycleSettingsController(),
                permanent: true,
              )
              as _LifecycleSettingsController;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(controller.refreshes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(controller.refreshes, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await Get.delete<SettingsController>(force: true);
    },
    skip: !kIsWeb,
  );

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

  testWidgets('WebAuthn SM2 settings open their dialog from device settings', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1536, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller =
        Get.put<SettingsController>(
              _Sm2SettingsController()
                ..polled = true
                ..key = ScreenshotMode.canoKey(),
            )
            as _Sm2SettingsController;
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(S.current.settingsWebAuthnSm2Support));
    await tester.pumpAndSettle();
    expect(controller.sm2Reads, 0);
    await tester.tap(find.text(S.current.settingsWebAuthnSm2Support));
    await tester.pumpAndSettle();
    expect(controller.sm2Reads, 1);
    expect(find.byType(Sm2ConfigDialog), findsOneWidget);
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(Sm2ConfigDialog), findsNothing);
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

CanoKey _legacyKey(String firmware, {bool ndefEnabled = true}) => CanoKey(
  model: 'CanoKey',
  sn: 'FFFFFFFF',
  chipId: '0102',
  firmwareVersion: firmware,
  functionSetVersion: CanoKey.functionSetFromFirmwareVersion(firmware),
  ledOn: true,
  hotpOn: false,
  ndefReadonly: false,
  ndefEnabled: ndefEnabled,
  webusbLandingEnabled: false,
  keyboardWithReturn: false,
  sigTouch: false,
  decTouch: false,
  autTouch: false,
  touchCacheTime: 0,
  nfcEnabled: true,
);

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
