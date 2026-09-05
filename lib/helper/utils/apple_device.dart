import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_detector/platform_detector.dart';

class AppleDevice {
  static bool _isIPad = false;

  static bool get isIPad => _isIPad;

  static Future<void> initialize() async {
    if (!isIOSApp()) {
      _isIPad = false;
      return;
    }

    try {
      final info = await DeviceInfoPlugin().iosInfo;
      _isIPad = looksLikeIPad(info.model, info.utsname.machine);
    } catch (_) {
      _isIPad = false;
    }
  }

  @visibleForTesting
  static bool looksLikeIPad(String model, String machine) {
    return model.toLowerCase() == 'ipad' ||
        machine.toLowerCase().startsWith('ipad');
  }

  @visibleForTesting
  static void setIPadForTesting(bool value) {
    _isIPad = value;
  }
}
