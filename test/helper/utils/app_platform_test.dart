import 'package:canokey_console/helper/utils/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in TargetPlatform.values) {
    test('classifies $platform without treating browsers as native apps', () {
      debugDefaultTargetPlatformOverride = platform;
      expect(isWeb(), kIsWeb);
      expect(isAndroidApp(), !kIsWeb && platform == TargetPlatform.android);
      expect(isIOSApp(), !kIsWeb && platform == TargetPlatform.iOS);
      final mobile =
          platform == TargetPlatform.android || platform == TargetPlatform.iOS;
      expect(isMobile(), !kIsWeb && mobile);
      expect(isDesktop(), !kIsWeb && !mobile);
    });
  }
}
