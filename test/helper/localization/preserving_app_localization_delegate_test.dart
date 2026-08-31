import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/localization/preserving_app_localization_delegate.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores the selected app locale after an en-US override', () async {
    final originalLanguage = ThemeCustomizer.instance.currentLanguage;
    final originalDefaultLocale = Intl.defaultLocale;

    try {
      final chinese = Language.languages[1];
      ThemeCustomizer.instance.currentLanguage = chinese;
      await S.delegate.load(chinese.locale);

      await const PreservingAppLocalizationDelegate().load(
        const Locale('en', 'US'),
      );

      expect(Intl.defaultLocale, 'zh_Hans');
      expect(S.current.about, '关于');
    } finally {
      ThemeCustomizer.instance.currentLanguage = originalLanguage;
      await S.delegate.load(originalLanguage.locale);
      Intl.defaultLocale = originalDefaultLocale;
    }
  });
}
