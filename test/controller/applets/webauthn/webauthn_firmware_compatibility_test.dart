import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter_test/flutter_test.dart';

class _ConfigController extends WebAuthnController {
  _ConfigController(this._hasInfo);

  final bool _hasInfo;

  @override
  bool get hasConfigInfo => _hasInfo;
}

void main() {
  WebAuthnController configControllerFor(String version, {bool hasInfo = true}) {
    final controller = _ConfigController(hasInfo);
    controller.firmwareVersion = FirmwareVersion.parse(version);
    controller.functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(version);
    return controller;
  }

  test('gates authenticator config by firmware and getInfo options', () {
    for (final version in ['3.0.0', '3.0.3', '3.1.0', '3.1.1']) {
      expect(configControllerFor(version).supportsConfig, isTrue,
          reason: version);
      expect(configControllerFor(version, hasInfo: false).supportsConfig,
          isFalse,
          reason: '$version without config options in getInfo');
    }

    for (final version in ['1.6.2', '2.0.1']) {
      expect(configControllerFor(version).supportsConfig, isFalse,
          reason: version);
    }
  });

  test('does not access the card when authenticator config is hidden',
      () async {
    final controller = configControllerFor('2.0.1');

    expect(await controller.toggleAlwaysUv(), isFalse);
    expect(await controller.setMinPinLength(8, false), isFalse);
    expect(await controller.enableLongTouchForReset(), isFalse);
  });
}
