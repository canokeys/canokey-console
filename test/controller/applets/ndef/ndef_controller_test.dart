import 'dart:typed_data';

import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:ndef/ndef.dart';

void main() {
  test('editing records logs operations without changing editor behavior', () {
    final store = LogStore();
    addTearDown(store.dispose);
    final controller = _LoggedNdefController(store);
    final first = TextRecord(text: 'first');
    final second = TextRecord(text: 'second');
    controller.addRecord(first);
    controller.addRecord(second);
    controller.moveRecord(0, 1);
    expect(controller.records, [second, first]);
    controller.removeRecord(0);
    expect(controller.records, [first]);
    expect(controller.dirty, isTrue);
    expect(store.text, contains('Call NdefController.addRecord'));
    expect(store.text, contains('Call NdefController.moveRecord'));
    expect(store.text, contains('Call NdefController.removeRecord'));
    final before = store.text;
    store.setEnabled(false);
    controller.updateRecord(0, second);
    expect(controller.records, [second]);
    expect(store.text, before);
  });

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

class _LoggedNdefController extends NdefController {
  _LoggedNdefController(LogStore store)
      : log = DiagnosticLogger('NDEF:Controller', store: store);

  @override
  final Logger log;
}
