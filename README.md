# CanoKey Console

CanoKey Console manages your CanoKey over USB or NFC. Use it to manage OATH one-time codes, FIDO passkeys, PIV and OpenPGP keys, and device settings.

## Install

| Platform | Where to get Console |
| --- | --- |
| Web | [CanoKey Console Web](https://console.canokeys.org) in Chrome or another browser with WebUSB |
| Android | [Google Play](https://play.google.com/store/apps/details?id=org.canokeys.console) |
| iPhone and iPad | [App Store](https://apps.apple.com/app/canokey-console/id6476454147) |
| Windows | [GitHub Releases](https://github.com/canokeys/canokey-console/releases/latest) |
| macOS | [Homebrew](https://github.com/canokeys/homebrew-tap) |
| Linux | [Snap Store](https://snapcraft.io/canokey-console) |

On **Windows**, extract the entire ZIP and run `canokey-console.exe`. Keep the DLLs and `data` folder alongside it.

On **macOS**, install with Homebrew. Console supports macOS 12 and later on Intel and Apple Silicon.

```sh
brew install --cask canokeys/tap/canokey-console
```

On **Linux**, connect the Snap’s PC/SC interface to use CanoKey over USB. The Snap is available for AMD64 and ARM64.

```sh
sudo snap install canokey-console
sudo snap connect canokey-console:pcscd
snap run canokey-console
```

## Use your CanoKey

- To read a CanoKey over NFC, open the applet you want to use. Start a scan when prompted and hold the key near your phone until reading finishes.
- To use CanoKey to sign in to a Mac and unlock its login keychain, follow the [macOS login guide](docs/piv-macos-login.md).

## Troubleshooting

Open **Settings > View Logs** to inspect or copy recent diagnostic messages. The app keeps up to 500 entries in memory for the current session. You can pause recording from the same screen. Review copied logs before sharing them.

For more help, see the [CanoKey documentation](https://docs.canokeys.org) or open an issue on [GitHub](https://github.com/canokeys/canokey-console/issues).

## License

CanoKey Console is distributed under the [MIT License](LICENSE).
