import 'dart:async';

import 'package:canokey_console/src/rust/frb_generated.dart';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/services/navigation_service.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_notifier.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/routes.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:provider/provider.dart';

final log = Logger('Console:main');

Future<void> main() async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await LocalStorage.init();
  AppStyle.init();
  Language.init();

  if (!isWeb()) {
    SmartCard.pollCcid();
  } else {
    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.webBrowserInfo;
    if (info.browserName != BrowserName.chrome && info.browserName != BrowserName.edge) {
      log.severe('Browser not supported');
      Layout.notSupported = true;
    }
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
