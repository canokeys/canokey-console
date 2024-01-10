import 'package:flutter/material.dart';

class NavigationService {
  static BuildContext? globalContext;

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void registerContext(BuildContext context, {bool update = false}) {
    if (globalContext == null || update) {
      globalContext = context;
    }
  }
}
