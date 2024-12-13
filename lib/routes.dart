import 'package:canokey_console/views/applets/oath/oath_page.dart';
import 'package:canokey_console/views/applets/pass/pass_page.dart';
import 'package:canokey_console/views/applets/piv.dart';
import 'package:canokey_console/views/applets/webauthn/webauthn_page.dart';
import 'package:canokey_console/views/applets/settings/settings_page.dart';
import 'package:canokey_console/views/starter_screen.dart';
import 'package:get/get.dart';

getPageRoute() {
  var routes = [
    GetPage(name: '/', page: () => const StarterScreen()),

    // ----------------Applets----------------------------------
    GetPage(name: '/applets/webauthn', page: () => const WebAuthnPage()),
    GetPage(name: '/applets/oath', page: () => const OathPage()),
    GetPage(name: '/applets/pass', page: () => const PassPage()),
    GetPage(name: '/applets/piv', page: () => const PivPage()),

    GetPage(name: '/settings', page: () => const SettingsPage()),
  ];

  return routes.map((e) => GetPage(name: e.name, page: e.page, middlewares: e.middlewares, transition: Transition.noTransition)).toList();
}
