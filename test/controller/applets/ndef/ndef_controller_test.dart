import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';

void main() {
  test('editing records updates their order and marks the document dirty', () {
    final controller = NdefController();
    final first = TextRecord(text: 'first');
    final second = TextRecord(text: 'second');
    controller.addRecord(first);
    controller.addRecord(second);
    controller.moveRecord(0, 1);
    expect(controller.records, [second, first]);
    controller.removeRecord(0);
    expect(controller.records, [first]);
    expect(controller.dirty, isTrue);
    controller.updateRecord(0, second);
    expect(controller.records, [second]);
  });
}
