import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/localization/preserving_app_localization_delegate.dart';
import 'package:canokey_console/helper/services/navigation_service.dart';
import 'package:canokey_console/helper/services/log_navigation_observer.dart';
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
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/fido2_backend.dart';
import 'package:canokey_console/routes.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:canokey_console/helper/webusb_dummy.dart'
    if (dart.library.html) 'package:canokey_console/helper/webusb.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  final log = Logging.logger('Application');
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    log.e('Flutter framework error',
        error: details.exception, stackTrace: details.stack);
    previousErrorHandler?.call(details);
  };
  log.i('CanoKey Console started');
  if (ScreenshotMode.enabled) {
    WidgetsFlutterBinding.ensureInitialized();
    await loadSnapChineseFont();
    await RustLib.init();
    await initializeFido2Backend();
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
    await initializeFido2Backend();
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
      Layout.notSupported = !await isWebUsbAvailable();
      if (!Layout.notSupported) {
        WebUSB.onDisconnect = SmartCard.onWebUSBDisconnected;
      }
    }

    Widget app = ChangeNotifierProvider<AppNotifier>(
      create: (context) => AppNotifier(),
      child: MyApp(),
    );

    runApp(app);
  }, (exception, stackTrace) {
    log.e('Unhandled application error',
        error: exception, stackTrace: stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _navigationObserver = LogNavigationObserver();

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
            navigatorObservers: [_navigationObserver],
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
