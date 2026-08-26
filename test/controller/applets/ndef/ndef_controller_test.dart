import 'dart:typed_data';

import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NdefController APDUs', () {
    test('builds short READ BINARY commands', () {
      expect(NdefController.readBinaryApdu(0x0102, 0xf0), '00B00102F0');
    });

    test('builds short UPDATE BINARY commands', () {
      expect(
        NdefController.updateBinaryApdu(0, Uint8List.fromList([0x00, 0x11])),
        '00D60000020011',
      );
    });

    test('rejects APDUs outside the short command range', () {
      expect(() => NdefController.readBinaryApdu(0, 0), throwsRangeError);
      expect(
        () => NdefController.updateBinaryApdu(0, Uint8List(256)),
        throwsRangeError,
      );
    });
  });
}
