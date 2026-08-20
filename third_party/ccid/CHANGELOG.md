## Unreleased

* Run Android CCID I/O off the Flutter platform thread and serialize operations.
* Complete pending callbacks on permission denial, disconnect, and plugin teardown.
* Release Android USB interfaces and validate USB descriptor and response lengths.
* Serialize CryptoTokenKit sessions and handle disconnect/reconnect without stale callbacks.
* Validate native method arguments and APDU hex strings instead of crashing.
* Keep the desktop PC/SC context alive until the final connected card disconnects.

## 0.1.8

* Improve compatibility

## 0.1.7

* Downgrade to Flutter 3.24

## 0.1.6

* No library functional changes
* Android: bump Kotlin to 2.1.0, lower JVM Target to 1.8
* iOS / macOS: add support for Swift Package Manager

## 0.1.5

* Use darwin shared library

## 0.1.4

* Fix state related issues on Android

## 0.1.3

* Use `RECEIVER_EXPORTED` for broadcast

## 0.1.2

* Fix Android 14's compatibility issue.

## 0.1.1

* Fix the pod name for iOS.

## 0.1.0

* Add basic support for Windows / Linux (via PCSC), macOS / iOS (via CryptoTokenKit), and Android (via USB operations).
