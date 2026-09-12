import 'dart:convert';

import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => SmartCard.connectionType = ConnectionType.none);

  test('legacy firmware does not read the feature configuration', () async {
    final transport = _Transport([
      '9000',
      '${hex.encode(utf8.encode('3.0.0'))}9000',
    ]);
    final status = await AppletSwitches.readStatus(
      client: AdminCardClient(transport: transport),
    );
    expect(transport.commands, ['00A4040005F000000000', '0031000000']);
    expect(status.functionSetVersion, FunctionSetVersion.v4);
    expect(status.featureSwitchesSupported, isFalse);
    expect(status.passEnabled, isTrue);
    expect(status.pivEnabled, isTrue);
  });

  test(
    'reads current feature switches once and distinguishes USB from NFC',
    () async {
      // Pass, OpenPGP NFC and PIV USB enabled; the other three bits disabled.
      final transport = _Transport([
        '9000',
        '${hex.encode(utf8.encode('3.1.0'))}9000',
        '01000001000d9000',
      ]);
      final status = await AppletSwitches.readStatus(
        client: AdminCardClient(transport: transport),
      );
      expect(transport.commands, [
        '00A4040005F000000000',
        '0031000000',
        '0042000000',
      ]);
      expect(status.featureSwitchesSupported, isTrue);
      expect(status.passEnabled, isTrue);
      expect(status.webAuthnEnabled, isFalse);
      SmartCard.connectionType = ConnectionType.ccid;
      expect(status.openPgpEnabled, isFalse);
      expect(status.pivEnabled, isTrue);
      SmartCard.connectionType = ConnectionType.nfc;
      expect(status.openPgpEnabled, isTrue);
      expect(status.pivEnabled, isFalse);
    },
  );

  test('missing feature bytes keep applets enabled for compatibility', () {
    for (final version in FunctionSetVersion.values) {
      final status = AppletSwitchStatus.fromConfig(
        firmwareVersion: const FirmwareVersion(3, 1, 0),
        functionSetVersion: version,
        config: const [0, 0, 0, 0, 0],
      );
      expect(status.featureSwitchesSupported, isFalse);
      expect([
        status.passEnabled,
        status.openPgpUsbEnabled,
        status.openPgpNfcEnabled,
        status.pivUsbEnabled,
        status.pivNfcEnabled,
        status.webAuthnEnabled,
      ], everyElement(isTrue));
    }
  });

  test('updating selected switches preserves other and reserved bits', () {
    expect(
      AppletSwitches.updateFeatureMask(0xca, {
        Func.passSwitch: true,
        Func.pivCcIdSwitch: false,
        Func.webAuthnSwitch: true,
      }),
      0xe3,
    );
  });
}

class _Transport implements ApduTransport {
  _Transport(this.responses);
  final List<String> responses;
  final List<String> commands = [];
  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses.removeAt(0);
  }
}
