import 'package:flutter/foundation.dart';

// Browser identity must not depend on recognizing an operating system in the
// user agent (ChromeOS uses CrOS, and browsers may reduce or omit OS details).
bool isWeb() => kIsWeb;

bool isAndroidApp() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool isIOSApp() => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

// These describe native apps; browsers on phones still use the WebUSB flow.
bool isMobile() => isAndroidApp() || isIOSApp();

bool isDesktop() => !kIsWeb && !isMobile();
