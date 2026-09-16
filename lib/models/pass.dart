import 'dart:typed_data';

enum PassSlotType { none, oath, static, hmacSha1, unknown }

class PassSlot {
  final PassSlotType type;
  final String name;
  final bool withEnter;

  PassSlot({required this.type, required this.name, required this.withEnter});

  static PassSlot empty() {
    return PassSlot(type: PassSlotType.none, name: '', withEnter: false);
  }

  // Decodes the bridge encoding, two slots in total:
  // [short_len] ++ short ++ [long_len] ++ long.
  // For each slot, the first byte is the type.
  // For PASS_SLOT_OFF, there is no more data.
  // For PASS_SLOT_STATIC, the second byte is with_enter.
  // For PASS_SLOT_HMACSHA1, there is no more data because the key is never dumped back.
  // For PASS_SLOT_OATH, the next byte is the length of the name, followed by the name, and the next byte is with_enter.
  // Any other type byte is an unknown state carried verbatim.
  static List<PassSlot> decode(Uint8List data) {
    var offset = 0;
    List<int> nextState() {
      if (offset >= data.length) {
        throw const FormatException('Missing Pass slot state');
      }
      final length = data[offset++];
      if (offset + length > data.length) {
        throw const FormatException('Truncated Pass slot state');
      }
      final state = data.sublist(offset, offset + length);
      offset += length;
      return state;
    }

    final slots = [_decodeState(nextState()), _decodeState(nextState())];
    if (offset != data.length) {
      throw const FormatException('Trailing Pass slot data');
    }
    return slots;
  }

  static PassSlot _decodeState(List<int> state) {
    if (state.isEmpty) {
      throw const FormatException('Empty Pass slot state');
    }
    switch (state[0]) {
      case 0x00:
        if (state.length != 1) {
          throw const FormatException('Malformed empty Pass slot');
        }
        return PassSlot(type: PassSlotType.none, name: '', withEnter: false);
      case 0x02:
        if (state.length != 2) {
          throw const FormatException('Malformed static Pass slot');
        }
        return PassSlot(
          type: PassSlotType.static,
          name: '',
          withEnter: state[1] == 1,
        );
      case 0x03:
        if (state.length != 1) {
          throw const FormatException('Malformed HMAC-SHA1 Pass slot');
        }
        return PassSlot(
          type: PassSlotType.hmacSha1,
          name: '',
          withEnter: false,
        );
      case 0x01:
        final nameLength = state.length > 1 ? state[1] : -1;
        if (state.length != nameLength + 3) {
          throw const FormatException('Malformed OATH Pass slot');
        }
        return PassSlot(
          type: PassSlotType.oath,
          name: String.fromCharCodes(state.sublist(2, 2 + nameLength)),
          withEnter: state[2 + nameLength] == 1,
        );
      default:
        return PassSlot(type: PassSlotType.unknown, name: '', withEnter: false);
    }
  }
}
