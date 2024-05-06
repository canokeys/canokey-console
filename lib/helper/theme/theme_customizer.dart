import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/services/navigation_service.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef ThemeChangeCallback = void Function(ThemeCustomizer oldVal, ThemeCustomizer newVal);

class ThemeCustomizer {
  ThemeCustomizer();

  static final List<ThemeChangeCallback> _notifier = [];

  Language currentLanguage = Language.languages.first;

  ThemeMode theme = ThemeMode.light;
  ThemeMode leftBarTheme = ThemeMode.light;
  ThemeMode rightBarTheme = ThemeMode.light;
  ThemeMode topBarTheme = ThemeMode.light;

  bool leftBarCondensed = false;

  static ThemeCustomizer instance = ThemeCustomizer();
  static ThemeCustomizer oldInstance = ThemeCustomizer();

  static void addListener(ThemeChangeCallback callback) {
    _notifier.add(callback);
  }

  static void removeListener(ThemeChangeCallback callback) {
    _notifier.remove(callback);
  }

  static void _notify() {
    AdminTheme.setTheme();
    if (NavigationService.globalContext != null) {
      Provider.of<AppNotifier>(NavigationService.globalContext!, listen: false).updateTheme(instance);
    }
    for (var value in _notifier) {
      value(oldInstance, instance);
    }
  }

  static void setTheme(ThemeMode theme) {
    oldInstance = instance.clone();
    instance.theme = theme;
    instance.leftBarTheme = theme;
    instance.rightBarTheme = theme;
    instance.topBarTheme = theme;
    _notify();
  }

  static Future<void> changeLanguage(Language language) async {
    oldInstance = instance.clone();
    ThemeCustomizer.instance.currentLanguage = language;
  }

  static void toggleLeftBarCondensed() {
    instance.leftBarCondensed = !instance.leftBarCondensed;
    _notify();
  }

  ThemeCustomizer clone() {
    var tc = ThemeCustomizer();
    tc.theme = theme;
    tc.rightBarTheme = rightBarTheme;
    tc.leftBarTheme = leftBarTheme;
    tc.topBarTheme = topBarTheme;
    tc.leftBarCondensed = leftBarCondensed;
    tc.currentLanguage = currentLanguage.clone();
    return tc;
  }

  @override
  String toString() {
    return 'ThemeCustomizer{theme: $theme}';
  }
}
