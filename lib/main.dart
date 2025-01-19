import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/services/navigation_service.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_notifier.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/rust_license.dart';
import 'package:canokey_console/routes.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:canokey_console/helper/webusb_dummy.dart' if (dart.library.html) 'package:flutter_nfc_kit/webusb_interop.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await LocalStorage.init();
  AppStyle.init();
  Language.init();
  LicenseRegistry.addLicense(() => parseRustLicenses());

  if (!isWeb()) {
    SmartCard.pollCcid();
    if (isAndroidApp()) {
      SmartCard.startAndroidNfcHandler();
      Audio.init();
    }
  } else {
    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.webBrowserInfo;
    if (info.browserName != BrowserName.chrome && info.browserName != BrowserName.edge) {
      Layout.notSupported = true;
    }
    WebUSB.onDisconnect = SmartCard.onWebUSBDisconnected;
  }

  runApp(ChangeNotifierProvider<AppNotifier>(
    create: (context) => AppNotifier(),
    child: MyApp(),
  ));
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
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeCustomizer.instance.theme,
            navigatorKey: NavigationService.navigatorKey,
            initialRoute: LocalStorage.getStartPage() ?? '/',
            locale: ThemeCustomizer.instance.currentLanguage.locale,
            getPages: getPageRoute(),
            builder: (ctx, child) {
              NavigationService.registerContext(ctx);
              return child!;
            },
            localizationsDelegates: const [
              S.delegate,
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
