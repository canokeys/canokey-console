import 'dart:convert';
import 'dart:io';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves Chinese scripts and regional system locales', () {
    for (final code in ['zh_Hant', 'zh-Hant-TW', 'zh_TW', 'zh-HK', 'zh_MO']) {
      expect(Language.getLanguageFromCode(code).locale.scriptCode, 'Hant');
    }
    for (final code in ['zh', 'zh_CN', 'zh-SG', 'zh_Hans', 'zh-Hans-HK']) {
      expect(Language.getLanguageFromCode(code).locale.scriptCode, 'Hans');
    }
    expect(Language.getLanguageFromCode('en-US').locale.languageCode, 'en');
    expect(Language.getLanguageFromCode('fr').locale.languageCode, 'en');
    expect(Language.getLanguageFromCode('zh_Hant').languageName, '繁體中文');
  });

  test('traditional resources cover all messages and preserve placeholders',
      () {
    final source = jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final traditional =
        jsonDecode(File('lib/l10n/intl_zh_Hant.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = source.keys.where((key) => !key.startsWith('@'));
    expect(traditional.keys.where((key) => !key.startsWith('@')),
        unorderedEquals(keys));
    final placeholder = RegExp(r'\{\w+\}');
    for (final key in keys) {
      expect(traditional[key], isNotEmpty, reason: key);
      expect(
        placeholder.allMatches(traditional[key] as String).map((m) => m[0]),
        unorderedEquals(
            placeholder.allMatches(source[key] as String).map((m) => m[0])),
        reason: key,
      );
    }
  });

  test('loads traditional translations and interpolates messages', () async {
    await S.load(Language.getLanguageFromCode('zh_Hant').locale);
    expect(S.current.settings, '設定');
    expect(S.current.settingsFirmwareVersion, '韌體版本');
    expect(S.current.pivCertificate, '憑證');
    expect(S.current.ndefBytesUsed(3, 10), '已使用 3 / 10 位元組');
    await S.load(Language.languages.first.locale);
  });
}
