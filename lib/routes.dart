import 'package:canokey_console/views/applets/oath.dart';
import 'package:canokey_console/views/applets/pass.dart';
import 'package:canokey_console/views/applets/webauthn.dart';
import 'package:canokey_console/views/settings.dart';
import 'package:canokey_console/views/starter_screen.dart';
import 'package:get/get.dart';

getPageRoute() {
  var routes = [
    GetPage(name: '/', page: () => const StarterScreen()),

    // ----------------Applets----------------------------------
    GetPage(name: '/applets/webauthn', page: () => const WebAuthnPage()),
    GetPage(name: '/applets/oath', page: () => const OathPage()),
    GetPage(name: '/applets/pass', page: () => const PassPage()),

    GetPage(name: '/settings', page: () => const SettingsPage()),
  ];

  return routes
      .map((e) => GetPage(
          name: e.name,
          page: e.page,
          middlewares: e.middlewares,
          transition: Transition.noTransition))
      .toList();
}
