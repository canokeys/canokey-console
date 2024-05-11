import 'package:canokey_console/helper/tlv.dart';
import 'package:x509/src/x509_base.dart';

enum AlgorithmType {
  pin(0xFF),
  tdes(0x03),
  aes128(0x08),
  aes192(0x0A),
  aes256(0x0C),
  rsa1024(0x06),
  rsa2048(0x07),
  rsa3072(0x05),
  rsa4096(0x16),
  eccp256(0x11),
  eccp384(0x14),
  ed25519(0xE0),
  x25519(0xE1);

  const AlgorithmType(this.value);

  static AlgorithmType fromValue(int value) {
    switch (value) {
      case 0xFF:
        return AlgorithmType.pin;
      case 0x03:
        return AlgorithmType.tdes;
      case 0x08:
        return AlgorithmType.aes128;
      case 0x0A:
        return AlgorithmType.aes192;
      case 0x0C:
        return AlgorithmType.aes256;
      case 0x06:
        return AlgorithmType.rsa1024;
      case 0x07:
        return AlgorithmType.rsa2048;
      case 0x05:
        return AlgorithmType.rsa3072;
      case 0x16:
        return AlgorithmType.rsa4096;
      case 0x11:
        return AlgorithmType.eccp256;
      case 0x14:
        return AlgorithmType.eccp384;
      case 0xE0:
        return AlgorithmType.ed25519;
      case 0xE1:
        return AlgorithmType.x25519;
      default:
        throw ArgumentError('Invalid algorithm value: $value');
    }
  }

  final int value;
}

enum PinPolicy {
  defaultPolicy(0x00),
  never(0x01),
  once(0x02),
  always(0x03);

  const PinPolicy(this.value);

  static PinPolicy fromValue(int value) {
    switch (value) {
      case 0x00:
        return PinPolicy.defaultPolicy;
      case 0x01:
        return PinPolicy.never;
      case 0x02:
        return PinPolicy.once;
      case 0x03:
        return PinPolicy.always;
      default:
        throw ArgumentError('Invalid pin policy value: $value');
    }
  }

  final int value;
}

enum TouchPolicy {
  defaultPolicy(0x00),
  never(0x01),
  always(0x02),
  cached(0x03);

  const TouchPolicy(this.value);

  static TouchPolicy fromValue(int value) {
    switch (value) {
      case 0x00:
        return TouchPolicy.defaultPolicy;
      case 0x01:
        return TouchPolicy.never;
      case 0x02:
        return TouchPolicy.always;
      case 0x03:
        return TouchPolicy.cached;
      default:
        throw ArgumentError('Invalid touch policy value: $value');
    }
  }

  final int value;
}

enum Origin {
  generated(0x01),
  imported(0x02);

  const Origin(this.value);

  static Origin fromValue(int value) {
    switch (value) {
      case 0x01:
        return Origin.generated;
      case 0x02:
        return Origin.imported;
      default:
        throw ArgumentError('Invalid origin value: $value');
    }
  }

  final int value;
}

class SlotInfo {
  final int number;
  final AlgorithmType algorithm;
  final PinPolicy pinPolicy;
  final TouchPolicy touchPolicy;
  final Origin origin;
  final List<int> public;
  final bool defaultValue;
  final int retriesCount;
  final int remainingCount;
  List<int>? certBytes;
  X509Certificate? cert;

  SlotInfo(this.number, this.algorithm, this.pinPolicy, this.touchPolicy, this.origin, this.public, this.defaultValue, this.retriesCount, this.remainingCount);

  static SlotInfo parse(int number, List<int> buf) {
    Map map = TLV.parse(buf);
    var algo = AlgorithmType.fromValue(map[0x01][0]);
    var pinPolicy = PinPolicy.defaultPolicy;
    var touchPolicy = TouchPolicy.defaultPolicy;
    if (number != 0x80 && number != 0x81) {
      pinPolicy = PinPolicy.fromValue(map[0x02][0]);
      touchPolicy = TouchPolicy.fromValue(map[0x02][1]);
    }
    var origin = Origin.generated;
    if (number != 0x80 && number != 0x81 && number != 0x9B) {
      origin = Origin.fromValue(map[0x03][0]);
    }
    List<int> public = [];
    if (number != 0x80 && number != 0x81 && number != 0x9B) {
      public = map[0x04];
    }
    var defaultValue = false;
    if (number == 0x80 || number == 0x81 || number == 0x9B) {
      defaultValue = map[0x05][0] == 0x01;
    }
    var retriesCount = 0, remainingCount = 0;
    if (number == 0x80 || number == 0x81) {
      retriesCount = map[0x06][0];
      remainingCount = map[0x06][1];
    }
    return SlotInfo(number, algo, pinPolicy, touchPolicy, origin, public, defaultValue, retriesCount, remainingCount);
  }

  @override
  String toString() {
    return 'SlotInfo{number: $number, algorithm: $algorithm, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, origin: $origin, public: $public, defaultValue: $defaultValue, retries: $remainingCount/$retriesCount}';
  }
}
