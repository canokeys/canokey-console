import 'package:convert/convert.dart';

enum PassSlotType {
  none,
  oath,
  static,
}

class PassSlot {
  final PassSlotType type;
  final String name;
  final bool withEnter;

  PassSlot({required this.type, required this.name, required this.withEnter});

  static PassSlot empty() {
    return PassSlot(type: PassSlotType.none, name: '', withEnter: false);
  }

  // Parse slots from data, two in total.
  // For each slot, the first byte is the type.
  // For PASS_SLOT_OFF, there is no more data
  // For PASS_SLOT_STATIC, the second byte is with_enter
  // For PASS_SLOT_OATH, the next byte is the length of the name, followed by the name, and the next byte is with_enter
  static List<PassSlot> fromData(String hexData) {
    List<PassSlot> slots = [];
    int i = 0;
    while (i < hexData.length) {
      int type = int.parse(hexData.substring(i, i + 2), radix: 16);
      i += 2;
      if (type == 0) {
        // OFF
        slots.add(PassSlot(type: PassSlotType.none, name: '', withEnter: false));
      } else if (type == 1) {
        // OATH
        int nameLen = int.parse(hexData.substring(i, i + 2), radix: 16);
        i += 2;
        String nameHex = hexData.substring(i, i + nameLen * 2);
        String name = String.fromCharCodes(hex.decode(nameHex));
        i += nameLen * 2;
        int withEnter = int.parse(hexData.substring(i, i + 2), radix: 16);
        i += 2;
        slots.add(PassSlot(type: PassSlotType.oath, name: name, withEnter: withEnter == 1));
      } else if (type == 2) {
        // STATIC
        int withEnter = int.parse(hexData.substring(i, i + 2), radix: 16);
        i += 2;
        slots.add(PassSlot(type: PassSlotType.static, name: '', withEnter: withEnter == 1));
      }
    }
    return slots;
  }
}
