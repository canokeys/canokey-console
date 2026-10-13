@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/utils/app_platform.dart';
import 'package:canokey_console/helper/utils/apple_device.dart';
import 'package:flutter_test/flutter_test.dart';

@JS('navigator')
external JSObject get _navigator;

@JS('navigator.userAgent')
external JSString get _userAgent;

@JS('Object.defineProperty')
external JSObject _defineProperty(
  JSObject object,
  JSString key,
  JSObject value,
);

void _setUserAgent(String value) {
  _defineProperty(
    _navigator,
    'userAgent'.toJS,
    {'value': value, 'configurable': true}.jsify() as JSObject,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final agent in [
    'Mozilla/5.0 (X11; CrOS aarch64 16295.85.0) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/138.0.0.0 Safari/537.36',
    'UnknownBrowser/1.0',
  ]) {
    test('startup platform checks work with UA: $agent', () async {
      final original = _userAgent.toDart;
      addTearDown(() => _setUserAgent(original));
      _setUserAgent(agent);

      expect(isWeb(), isTrue);
      expect(isAndroidApp(), isFalse);
      expect(isIOSApp(), isFalse);
      expect(isMobile(), isFalse);
      expect(isDesktop(), isFalse);
      AppStyle.init();
      await AppleDevice.initialize();
      expect(AppleDevice.isIPad, isFalse);
    });
  }
}
