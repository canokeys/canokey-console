import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = Logging.logger('Console:helper:storage');

class LocalStorage {
  static const String _languageKey = 'lang_code';
  static const String _startPageKey = 'start_page';
  static const String _oathSortKey = 'oath_sort_alphabetically';
  static const String _webauthnSortKey = 'webauthn_sort_alphabetically';

  static SharedPreferences? _preferencesInstance;

  static SharedPreferences get preferences {
    if (_preferencesInstance == null) {
      throw ('Call LocalStorage.init() to initialize local storage');
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

  static Future<bool> setStartPage(String page) {
    return preferences.setString(_startPageKey, page);
  }

  static String? getStartPage() {
    return preferences.getString(_startPageKey);
  }

  static Future<bool> setPinCache(String sn, String tag, String? pin) {
    if (pin == null) {
      return preferences.remove('pin:$sn:$tag');
    }
    return preferences.setString('pin:$sn:$tag', pin);
  }

  static String? getPinCache(String sn, String tag) {
    return preferences.getString('pin:$sn:$tag');
  }

  static Future<void> clearPinCache() async {
    final keys = preferences.getKeys().where((key) => key.startsWith('pin:'));
    log.i('Clearing pin cache: $keys');
    await Future.wait(keys.map((key) => preferences.remove(key)));
  }

  static Future<bool> setOathSortAlphabetically(bool value) {
    return preferences.setBool(_oathSortKey, value);
  }

  static bool getOathSortAlphabetically() {
    return preferences.getBool(_oathSortKey) ?? false;
  }

  static Future<bool> setWebAuthnSortAlphabetically(bool value) {
    return preferences.setBool(_webauthnSortKey, value);
  }

  static bool getWebAuthnSortAlphabetically() {
    return preferences.getBool(_webauthnSortKey) ?? false;
  }
}
