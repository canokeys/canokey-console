import 'package:canokey_console/src/rust/api/protocol.dart';

enum PassSlotType { none, oath, static, hmacSha1, unknown }

class PassSlot {
  final PassSlotType type;
  final String name;
  final bool withEnter;

  PassSlot({required this.type, required this.name, required this.withEnter});

  static PassSlot empty() {
    return PassSlot(type: PassSlotType.none, name: '', withEnter: false);
  }

  factory PassSlot.fromResult(PassSlotData slot) => PassSlot(
    type: switch (slot.kind) {
      0 => PassSlotType.none,
      1 => PassSlotType.oath,
      2 => PassSlotType.static,
      3 => PassSlotType.hmacSha1,
      _ => PassSlotType.unknown,
    },
    name: String.fromCharCodes(slot.name),
    withEnter: slot.appendEnter,
  );
}
