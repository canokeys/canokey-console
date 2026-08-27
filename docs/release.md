# Mobile prerelease checklist

The current candidate is version `1.2.1` with build/version code `15`.

Before building, confirm in both App Store Connect and Google Play Console that
build number/version code `15` has not already been used. Increment the number
in `pubspec.yaml` if necessary.

## Prerequisites

- Flutter 3.44.4 and Rust 1.88.0.
- Ruby dependencies installed with `bundle install`.
- Android release keystore configured in `android/key.properties`.
- An Apple Distribution certificate and App Store provisioning profile, or an
  authenticated Xcode account with automatic signing access.
- App Store Connect API key JSON for non-interactive TestFlight uploads.
- Google Play service-account JSON with release access.

## Verification

From the repository root:

```sh
RUSTUP_TOOLCHAIN=1.88.0 flutter_rust_bridge_codegen generate
rustup run 1.88.0 cargo test --manifest-path rust/Cargo.toml
flutter test
dart analyze
flutter build ios --release --no-codesign
flutter build appbundle --release
```

Test NFC and CCID workflows on physical iOS and Android devices. On Android,
also verify that each selectable NFC sound plays and that disabling the setting
silences it.

## Build prerelease artifacts

```sh
(cd ios && bundle exec fastlane ios build_testflight)
(cd android && bundle exec fastlane android build_internal)
```

The artifacts are written to `dist/ios/CanoKey-Console.ipa` and
`dist/android/CanoKey-Console.aab`.

For a manual TestFlight submission, open Apple Transporter and add
`dist/ios/CanoKey-Console.ipa`.

## Upload explicitly

The build lanes never upload. Run the upload lanes only after reviewing the
artifacts and localized release notes:

```sh
(cd ios && APP_STORE_CONNECT_API_KEY_PATH=/absolute/path/to/api-key.json \
  bundle exec fastlane ios upload_testflight)

(cd android && GOOGLE_PLAY_JSON_KEY=/absolute/path/to/service-account.json \
  bundle exec fastlane android upload_internal)
```

The Google Play lane creates a draft internal release by default. Set
`GOOGLE_PLAY_RELEASE_STATUS=completed` to expose it to internal testers.
