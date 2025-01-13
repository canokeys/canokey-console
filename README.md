# CanoKey Console

![Build Apps](https://github.com/canokeys/canokey-console/actions/workflows/build.yml/badge.svg)
![Build and Deploy to Netlify](https://github.com/canokeys/canokey-console/actions/workflows/netlify.yml/badge.svg)

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
- iOS: Download from [App Store](https://apps.apple.com/app/canokey-console/id1234567890)

## Development

### Prerequisites

- Flutter SDK 3.24.5 or higher
- Dart SDK 3.1.2 or higher
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
flutter build linux
```

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
