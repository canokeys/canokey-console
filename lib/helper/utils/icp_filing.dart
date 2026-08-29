import 'package:flutter/foundation.dart';

const String icpFilingUrl = 'https://beian.miit.gov.cn';

/// ICP filing numbers required for distribution in mainland China.
/// iOS/Android always show the app filing number; web shows the site
/// filing number only on the official domain; other platforms hide it.
String? icpFilingNumber() {
  if (kIsWeb) {
    return Uri.base.host == 'console.canokeys.com'
        ? '粤ICP备2025399893号-1'
        : null;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    return '粤ICP备2025399893号-2A';
  }
  return null;
}
