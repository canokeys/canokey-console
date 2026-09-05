# CanoKey Console

![Build Apps](https://github.com/canokeys/canokey-console/actions/workflows/build.yml/badge.svg)
![Deploy Web App](https://github.com/canokeys/canokey-console/actions/workflows/deploy.yml/badge.svg)

CanoKey Console is a cross-platform application that allows you to manage your CanoKey via NFC or USB connections. Built with Flutter, it provides a modern and intuitive interface for interacting with your CanoKey device.

## Features

- 🔌 Connect to CanoKey via USB or NFC
- 🛠️ OATH-TOTP token management
- 🌐 Cross-platform support (Web, Android, iOS, Windows, macOS, Linux)
- 🌍 Internationalization support
- 🎨 Modern Material Design interface

## Installation

### Web Version

Visit our web application at [CanoKey Console Web](https://console.canokeys.org)

### Mobile Apps

- Android: Download from [Google Play Store](https://play.google.com/store/apps/details?id=org.canokeys.console)
- iOS: Download from [App Store](https://apps.apple.com/app/canokey-console/id6476454147)

## Development

### Prerequisites

- Flutter SDK 3.44.4
- Dart SDK 3.12.2 or higher
- Rust **nightly** toolchain with `rust-src` component installed (`rustup component add rust-src`)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/canokeys/canokey-console.git
   cd canokey-console
   ```

2. Install dependencies:
   ```bash
   cargo install flutter_rust_bridge_codegen cargo-bundle-licenses
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter_rust_bridge_codegen build-web --release # for web only, remove --release for debug Rust build (very slow when decoding qrcode!)
   flutter run
   ```

## Building

If you change any Rust dependencies (`Cargo.lock`), please run:

```bash
cd rust && cargo bundle-licenses -f json | jq '.third_party_libraries | del(.[].licenses)' > THIRD_PARTY_LICENSES.json
```

### Web

```bash
flutter_rust_bridge_codegen build-web --release
flutter build web
```

### Android

```bash
flutter build apk
```

### iOS

```bash
flutter build ios
```

### Desktop

```bash
flutter build windows
flutter build macos
```

### Linux Snap

Install the Linux build dependencies and Snapcraft, then build the release
bundle and package it:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev \
  liblzma-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libcurl4-openssl-dev openjdk-17-jdk
sudo snap install snapcraft --classic
flutter build linux --release
sudo sh -c 'umask 022; exec /snap/bin/snapcraft pack --destructive-mode'
```

The CI builds Snap packages natively for both AMD64 and ARM64.

Install and run the locally built package:

```bash
sudo snap install --dangerous ./canokey-console_*.snap
sudo snap connect canokey-console:pcscd
snap run canokey-console
```

The `pcscd` interface does not auto-connect by default. A Snap Store
auto-connection grant can remove the manual connection step for store installs.

## USB/IP Compatibility Tests

The USB/IP workflow tests Console's CCID protocol against every released firmware in the
[`canokey-usbip`](https://github.com/canokeys/canokey-usbip) release map. The matrix is generated
from the harness catalog, so newly cataloged firmware releases are included without duplicating
version lists in this repository. The development `head` entry is not a released firmware version.

The tests require a Linux host with the `canokey-usbip` runner prerequisites and a Flutter SDK.
To run one firmware locally:

```bash
git clone https://github.com/canokeys/canokey-usbip.git /tmp/canokey-usbip
flutter pub get
/tmp/canokey-usbip/compat/run \
  --core-ref 3.1.0 \
  --require ccid \
  --require pcsc \
  --test-command 'bash test/usbip/run.sh'
```

The smoke test performs read-only Admin, OpenPGP, PIV, OATH, NDEF, WebAuthn, and supported Pass
queries through the same `ccid` package used by Console. Its JSON result is stored with the USB/IP
diagnostics as `console-smoke.json`.

## Contributing

We welcome contributions! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:
- Open an issue on our [GitHub Issues](https://github.com/canokeys/canokey-console/issues) page
- Visit our [Documentation](https://docs.canokeys.org)
