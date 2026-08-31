import 'package:sentry_flutter/sentry_flutter.dart';

bool _sentryInitialized = false;

/// Marks Sentry as initialized. Call this when Sentry is initialized with
/// `SentryFlutter.init(..., appRunner: ...)` at startup.
void markSentryInitialized() {
  _sentryInitialized = true;
}

void configureSentry(SentryFlutterOptions options) {
  options.dsn = 'https://4484dcb1b124a87b0b12403fd5747134@o292813.ingest.us.sentry.io/4508702185750528';
}

/// Initializes Sentry at runtime if it has not been initialized yet.
///
/// Used when Sentry initialization was deferred at startup until the user
/// agrees to the privacy policy.
Future<void> initSentry() async {
  if (_sentryInitialized || Sentry.isEnabled) return;
  _sentryInitialized = true;
  await SentryFlutter.init(configureSentry);
}
