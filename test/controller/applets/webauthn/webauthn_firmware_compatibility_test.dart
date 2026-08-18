import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WebAuthnController controllerFor(String version) {
    final controller = WebAuthnController();
    controller.firmwareVersion = FirmwareVersion.parse(version);
    controller.functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(version);
    return controller;
  }

  test('shows SM2 settings only on supported firmware before 3.1.0', () {
    for (final version in ['3.0.0', '3.0.3']) {
      expect(controllerFor(version).supportsSm2Settings, isTrue,
          reason: version);
    }

    for (final version in [
      '2.0.1',
      '3.1.0-28-gd2820836',
      '3.1.0',
      '3.1.1',
    ]) {
      expect(controllerFor(version).supportsSm2Settings, isFalse,
          reason: version);
    }
  });

  test('does not access the card when SM2 settings are hidden', () async {
    final controller = controllerFor('3.1.1');

    expect(await controller.readSm2Config(), isNull);
  });
}
