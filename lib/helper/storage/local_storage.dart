import 'package:canokey_console/helper/localization/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _languageKey = "lang_code";

  static SharedPreferences? _preferencesInstance;

  static SharedPreferences get preferences {
    if (_preferencesInstance == null) {
      throw ("Call LocalStorage.init() to initialize local storage");
    }
    return _preferencesInstance!;
  }

  static Future<void> init() async {
    _preferencesInstance = await SharedPreferences.getInstance();
  }

  static Future<bool> setLanguage(Language language) {
    return preferences.setString(_languageKey, language.locale.toString());
  }

  static String? getLanguage() {
    return preferences.getString(_languageKey);
  }
}
