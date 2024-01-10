import 'dart:typed_data';

class TLV {
  static Map parse(List<int> buf) {
    return _parse(Uint8List.fromList(buf), 0, buf.length);
  }

  static Map _parse(Uint8List buf, int off, int len) {
    Map result = {};
    while (off < len) {
      int tagLength = _getTagLength(buf, off);
      int tag = _getTag(buf, off, tagLength);
      off += tagLength;
      if (off >= len) {
        throw FormatException("Illegal TLV length");
      }
      int lengthCount = _getLengthBytesCount(buf, off);
      int length = _getDataLength(buf, off);
      if (off + lengthCount + length > len) {
        throw FormatException("Illegal TLV length");
      }
      if (tag == 0x73) { // OpenPGP
        result[tag] = _parse(buf, off + lengthCount, off + lengthCount + length);
      } else {
        result[tag] = buf.sublist(off + lengthCount, off + lengthCount + length);
      }
      off += lengthCount + length;
    }
    return result;
  }

  static int _getTagLength(Uint8List buf, int off) {
    if ((buf[off] & 0x1F) == 0x1F) {
      int len = 2;
      for (int i = off + 1; i < off + 10; ++i) {
        if ((buf[i] & 0x80) != 0x80) break;
        ++len;
      }
      return len;
    }
    return 1;
  }

  static int _getTag(Uint8List buf, int off, int len) {
    int tag = buf[off];
    for (int i = 1; i < len; ++i) {
      tag = (tag << 8) + buf[off + i];
    }
    return tag;
  }

  static int _getLengthBytesCount(Uint8List buf, int off) {
    int len = buf[off] & 0xFF;
    if ((len & 0x80) == 0x80) {
      return 1 + (len & 0x7F);
    }
    return 1;
  }

  static int _getDataLength(Uint8List buf, int off) {
    int length = buf[off] & 0xFF;

    if ((length & 0x80) == 0x80) {
      int numberOfBytes = length & 0x7F;
      if (numberOfBytes > 3) {
        throw FormatException('At position $off the len is more then 3 [$numberOfBytes]');
      }

      length = 0;
      for (int i = off + 1; i < off + 1 + numberOfBytes; i++) {
        length = length * 0x100 + (buf[i] & 0xff);
      }
    }
    return length;
  }
}
