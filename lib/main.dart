import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/localization/preserving_app_localization_delegate.dart';
import 'package:canokey_console/helper/services/navigation_service.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_notifier.dart';
import 'package:canokey_console/helper/theme/snap_fonts.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/apple_device.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/rust_license.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/sentry_setup.dart';
import 'package:canokey_console/routes.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/views/privacy_consent_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:canokey_console/helper/webusb_dummy.dart'
    if (dart.library.html) 'package:flutter_nfc_kit/webusb_interop.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  if (ScreenshotMode.enabled) {
    WidgetsFlutterBinding.ensureInitialized();
    await loadSnapChineseFont();
    await LocalStorage.init();
    AppStyle.init();
    ThemeCustomizer.instance.currentLanguage = Language.languages[1];
    ThemeCustomizer.instance.theme = ThemeMode.light;
    runApp(
      ChangeNotifierProvider<AppNotifier>(
        create: (context) => AppNotifier(),
        child: const MyApp(),
      ),
    );
    return;
  }

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await loadSnapChineseFont();

    await RustLib.init();
    await LocalStorage.init();
    AppStyle.init();
    Language.init();
    LicenseRegistry.addLicense(() => parseRustLicenses());
    await AppleDevice.initialize();

    if (!isWeb()) {
      SmartCard.pollCcid();
      if (isAndroidApp()) {
        SmartCard.startAndroidNfcHandler();
        Audio.init();
      }
    } else {
      final deviceInfo = DeviceInfoPlugin();
      final info = await deviceInfo.webBrowserInfo;
      if (info.browserName != BrowserName.chrome &&
          info.browserName != BrowserName.edge) {
        Layout.notSupported = true;
      }
      WebUSB.onDisconnect = SmartCard.onWebUSBDisconnected;
    }

    Widget app = ChangeNotifierProvider<AppNotifier>(
      create: (context) => AppNotifier(),
      child: MyApp(),
    );

    // OPPO compliance: Chinese users on iOS/Android who have not agreed to
    // the privacy policy must not initialize Sentry before giving consent.
    if (requiresPrivacyConsent()) {
      runApp(app);
    } else {
      markSentryInitialized();
      await SentryFlutter.init(
        configureSentry,
        appRunner: () => runApp(app),
      );
    }
  }, (exception, stackTrace) async {
    await Sentry.captureException(exception, stackTrace: stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotifier>(
      builder: (_, notifier, ___) {
        return GlobalLoaderOverlay(
          overlayWidgetBuilder: (_) {
            //ignored progress for the moment
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SpinKitRotatingPlain(color: Colors.red, size: 25.0),
              ],
            );
          },
          child: GetMaterialApp(
            title: 'CanoKey Console',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeCustomizer.instance.theme,
            navigatorKey: NavigationService.navigatorKey,
            initialRoute: ScreenshotMode.enabled
                ? ScreenshotMode.initialRoute
                : LocalStorage.getStartPage() ?? '/',
            locale: ThemeCustomizer.instance.currentLanguage.locale,
            getPages: getPageRoute(),
            builder: (ctx, child) {
              NavigationService.registerContext(ctx);
              return child!;
            },
            localizationsDelegates: const [
              PreservingAppLocalizationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
          ),
        );
      },
    );
  }
}
