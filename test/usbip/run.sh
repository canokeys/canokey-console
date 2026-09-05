#!/usr/bin/env bash
set -euo pipefail

: "${CANOKEY_USBIP:?This test must run inside canokey-usbip compat/run}"
: "${CANOKEY_FIRMWARE_VERSION:?Missing firmware version from canokey-usbip}"
: "${CANOKEY_PCSC_READER:?Missing PC/SC reader from canokey-usbip}"
: "${CANOKEY_TEST_OUTPUT:?Missing artifact directory from canokey-usbip}"

if [[ ! -f .dart_tool/package_config.json ]]; then
  flutter pub get
fi

flutter test \
  --no-pub \
  --no-test-assets \
  --coverage \
  --coverage-path "$CANOKEY_TEST_OUTPUT/console-coverage.lcov" \
  --reporter expanded \
  test/usbip/console_smoke.dart
