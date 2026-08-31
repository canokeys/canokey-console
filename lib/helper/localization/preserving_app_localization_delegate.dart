import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:flutter/material.dart';

/// Prevents nested localization scopes from changing the app-wide locale.
///
/// Flutter's license page renders legal text in an en-US localization scope.
/// The generated [S] delegate writes every loaded locale to global Intl state,
/// so reload the selected app locale after servicing a nested override.
class PreservingAppLocalizationDelegate extends LocalizationsDelegate<S> {
  const PreservingAppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => S.delegate.isSupported(locale);

  @override
  Future<S> load(Locale locale) async {
    final appLocale = ThemeCustomizer.instance.currentLanguage.locale;
    final localization = await S.delegate.load(locale);

    if (locale.languageCode != appLocale.languageCode) {
      await S.delegate.load(appLocale);
    }

    return localization;
  }

  @override
  bool shouldReload(PreservingAppLocalizationDelegate old) => false;
}
