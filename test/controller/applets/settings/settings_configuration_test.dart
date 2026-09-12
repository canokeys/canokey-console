import 'dart:typed_data';

import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => SmartCard.connectionType = ConnectionType.ccid);
  tearDown(() => SmartCard.connectionType = ConnectionType.none);

  test(
    'configuration bytes retain their meaning across legacy firmware layouts',
    () async {
      for (final (firmware, config, hotp, ndef, keyboard, touch, cache) in [
        ('1.0.0', [1, 1, 1, 1, 0, 1, 9], true, false, false, true, 9),
        ('1.5.0', [1, 1, 1, 1, 1], true, true, false, false, 0),
        ('1.6.2', [1, 1, 1, 1, 1, 1], true, true, true, false, 0),
        ('3.0.0', [1, 1, 1, 1, 1], false, true, false, false, 0),
      ]) {
        final controller = _Controller(_Card(firmware, config));
        await controller.doRefreshData();
        final key = controller.key;
        expect(controller.polled, isTrue);
        expect(key.ledOn, isTrue);
        expect(key.ndefReadonly, isTrue);
        expect(key.hotpOn, hotp, reason: firmware);
        expect(key.ndefEnabled, ndef, reason: firmware);
        expect(key.webusbLandingEnabled, ndef, reason: firmware);
        expect(key.keyboardWithReturn, keyboard, reason: firmware);
        expect(key.sigTouch, touch, reason: firmware);
        expect(key.decTouch, isFalse);
        expect(key.autTouch, touch, reason: firmware);
        expect(key.touchCacheTime, cache, reason: firmware);
        expect(key.featureSwitchesSupported, isFalse);
        expect(key.passEnabled, isTrue);
      }
    },
  );
}

class _Controller extends SettingsController {
  _Controller(AdminCardClient client) : super(client: client);
  @override
  Future<bool> authenticate(String sn) async => true;
}

class _Card extends AdminCardClient {
  _Card(this.firmware, this.config);
  final String firmware;
  final List<int> config;
  @override
  Future<String> readFirmwareVersion() async => firmware;
  @override
  Future<String> readModel() async => 'CanoKey';
  @override
  Future<String> readChipId() async => '0102';
  @override
  Future<Uint8List> readConfig() async => Uint8List.fromList(config);
  @override
  Future<bool> readNfcEnabled() async => true;
}
