import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = Logging.logger('Console:helper:storage');

class LocalStorage {
  static const String _languageKey = 'lang_code';
  static const String _startPageKey = 'start_page';
  static const String _nfcSoundKey = 'nfc_sound';
  static const String _oathSortKey = 'oath_sort_alphabetically';
  static const String _webauthnSortKey = 'webauthn_sort_alphabetically';
  static const String _privacyAgreedKey = 'privacy_agreed';

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
    log.t('Call LocalStorage.setLanguage');
    return preferences.setString(_languageKey, language.locale.toString());
  }

  static String? getLanguage() {
    return preferences.getString(_languageKey);
  }

  static Future<bool> setStartPage(String page) {
    log.t('Call LocalStorage.setStartPage');
    return preferences.setString(_startPageKey, page);
  }

  static String? getStartPage() {
    return preferences.getString(_startPageKey);
  }

  static int? getNfcSound() {
    return preferences.getInt(_nfcSoundKey);
  }

  // Generations coordinate local credential caches without storing secrets here.
  static final Map<String, int> _credentialGenerations = {};
  static int _generation = 0;
  static int credentialGeneration(String sn, String tag) =>
      _credentialGenerations.putIfAbsent('pin:$sn:$tag', () => _generation);

  static void _invalidateCredential(String key) {
    _credentialGenerations[key] = ++_generation;
  }

  /// Reset/change may have committed even when its acknowledgment is lost.
  static Future<void> clearPinCacheForDevice(String sn) async {
    final prefix = 'pin:$sn:';
    final keys = {
      ..._credentialGenerations.keys,
      ...preferences.getKeys(),
    }.where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      _invalidateCredential(key);
      await preferences.remove(key);
    }
  }

  static Future<bool> setPinCache(String sn, String tag, String? pin) {
    log.t('Call LocalStorage.setPinCache');
    if (pin == null) {
      _invalidateCredential('pin:$sn:$tag');
      return preferences.remove('pin:$sn:$tag');
    }
    return preferences.setString('pin:$sn:$tag', pin);
  }

  static String? getPinCache(String sn, String tag) {
    return preferences.getString('pin:$sn:$tag');
  }

  static Future<void> clearPinCache() async {
    log.t('Call LocalStorage.clearPinCache');
    final keys = {
      ..._credentialGenerations.keys,
      ...preferences.getKeys(),
    }.where((key) => key.startsWith('pin:')).toList();
    for (final key in keys) {
      _invalidateCredential(key);
    }
    log.i('Clearing pin cache: $keys');
    await Future.wait(keys.map((key) => preferences.remove(key)));
  }

  static Future<bool> setNfcSound(int sound) {
    log.t('Call LocalStorage.setNfcSound');
    return preferences.setInt(_nfcSoundKey, sound);
  }

  static Future<bool> setOathSortAlphabetically(bool value) {
    log.t('Call LocalStorage.setOathSortAlphabetically');
    return preferences.setBool(_oathSortKey, value);
  }

  static bool getOathSortAlphabetically() {
    return preferences.getBool(_oathSortKey) ?? false;
  }

  static Future<bool> setWebAuthnSortAlphabetically(bool value) {
    log.t('Call LocalStorage.setWebAuthnSortAlphabetically');
    return preferences.setBool(_webauthnSortKey, value);
  }

  static bool getWebAuthnSortAlphabetically() {
    return preferences.getBool(_webauthnSortKey) ?? false;
  }

  static Future<bool> setPrivacyAgreed(bool value) {
    log.t('Call LocalStorage.setPrivacyAgreed');
    return preferences.setBool(_privacyAgreedKey, value);
  }

  static bool isPrivacyAgreed() {
    return preferences.getBool(_privacyAgreedKey) ?? false;
  }
}

/// A page-local credential cache invalidated by device PIN changes/resets on
/// another page. Values are inputs only and never assert live authentication.
class CredentialCache {
  CredentialCache(this.tag);
  final String tag;
  final Map<String, (String, int)> _entries = {};

  String? operator [](String sn) {
    final entry = _entries[sn];
    if (entry == null) return null;
    if (entry.$2 != LocalStorage.credentialGeneration(sn, tag)) {
      _entries.remove(sn);
      return null;
    }
    return entry.$1;
  }

  void operator []=(String sn, String value) {
    _entries[sn] = (value, LocalStorage.credentialGeneration(sn, tag));
  }

  bool containsKey(String sn) => this[sn] != null;
  void remove(String sn) => _entries.remove(sn);
  void clear() => _entries.clear();
}
