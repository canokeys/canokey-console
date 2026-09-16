import 'package:intl/intl.dart';

/// Build metadata injected at compile time via `--dart-define`; both are
/// empty in local development builds.
abstract final class BuildInfo {
  /// Full commit hash of the build, or empty when not injected.
  static const commit = String.fromEnvironment('BUILD_COMMIT');

  /// UTC build timestamp in ISO 8601, or empty when not injected.
  static const time = String.fromEnvironment('BUILD_TIME');

  /// Short commit hash for display.
  static String get shortCommit =>
      commit.length > 7 ? commit.substring(0, 7) : commit;

  /// The build time in the local timezone, e.g. `2026-09-16 21:48`, or empty
  /// when not injected or unparseable.
  static String get localTime {
    final parsed = DateTime.tryParse(time);
    if (parsed == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
  }

  /// The GitHub page of the exact commit, or empty when not injected.
  static String get commitUrl =>
      commit.isEmpty
          ? ''
          : 'https://github.com/canokeys/canokey-console/commit/$commit';
}
