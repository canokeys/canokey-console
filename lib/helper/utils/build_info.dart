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
}
