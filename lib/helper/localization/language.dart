import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart' if (dart.library.html) 'package:intl/intl_browser.dart';

class Language {
  final Locale locale;
  final String languageName;

  static List<Language> languages = [
    Language(Locale('en'), "English"),
    Language(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'), "简体中文"),
  ];

  Language(this.locale, this.languageName);

  static bool init() {
    ThemeCustomizer.instance.currentLanguage = getCurrentLanguage();
    return true;
  }

  static List<Locale> getLocales() {
    return languages.map((e) => e.locale).toList();
  }

  static List<String> getLanguagesCodes() {
    return languages.map((e) => e.locale.languageCode).toList();
  }

  static Language getSystemLanguage() {
    findSystemLocale();
    if (Intl.systemLocale.startsWith('zh')) {
      return languages[1]; // zh-Hans
    } else {
      return languages[0]; // en
    }
  }

  static Language getCurrentLanguage() {
    Language? language;
    String? langCode = LocalStorage.getLanguage();
    if (langCode != null) {
      language = getLanguageFromCode(langCode);
    } else {
      language = getSystemLanguage();
    }
    return language;
  }

  static Language getLanguageFromCode(String code) {
    Language selectedLang = languages.first;
    for (var language in languages) {
      if (language.locale.toString() == code) selectedLang = language;
    }
    return selectedLang;
  }

  Language clone() {
    return Language(locale, languageName);
  }

  @override
  String toString() {
    return 'Language{locale: $locale, languageName: $languageName}';
  }
}
