# ccid

[![pub version](https://img.shields.io/pub/v/ccid)](https://pub.dev/packages/ccid)
[![Build Example App](https://github.com/nfcim/ccid/actions/workflows/example-app.yaml/badge.svg)](https://github.com/nfcim/ccid/actions/workflows/example-app.yaml)

A Flutter plugin for reading and writing smart cards using the CCID protocol with PC/SC-like APIs.

## Installation

### Android

This plugin uses AGP 8.7, thus requires Gradle 8.7+ (which needs Java 17+ to run).

### Linux / Windows

This plugin uses [`dart_pcsc`](https://pub.dev/packages/dart_pcsc), thus has a runtime dependency on [`PCSCLite`](https://pcsclite.apdu.fr/) to provide PC/SC APIs on Linux:

* Debian / Ubuntu: `sudo apt-get install pcscd libpcsclite1`
* RHEL / Fedora: `sudo dnf install pcsc-lite`

Should you encounter any permission problem, please check [README.polkit](https://github.com/LudovicRousseau/PCSC/blob/master/doc/README.polkit) from PCSCLite.

### macOS / iOS

This plugin uses [CryptoTokenKit](https://developer.apple.com/documentation/cryptotokenkit) on macOS, 
which is available since macOS 10.10 / iOS 13.0.

The `com.apple.security.smartcard` entitlement is required.
