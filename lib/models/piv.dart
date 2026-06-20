import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:get/get.dart';

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
  eccp521(0x15),
  secp256k1(0x53),
  sm2(0x54),
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
      case 0x15:
        return AlgorithmType.eccp521;
      case 0x53:
        return AlgorithmType.secp256k1;
      case 0x54:
        return AlgorithmType.sm2;
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

class PivAlgorithmExtensionConfig {
  final bool enabled;
  final int ed25519;
  final int rsa3072;
  final int rsa4096;
  final int x25519;
  final int secp256k1;
  final int sm2;
  final int secp521r1;

  const PivAlgorithmExtensionConfig({
    required this.enabled,
    required this.ed25519,
    required this.rsa3072,
    required this.rsa4096,
    required this.x25519,
    required this.secp256k1,
    required this.sm2,
    required this.secp521r1,
  });

  static const defaults = PivAlgorithmExtensionConfig(
    enabled: true,
    ed25519: 0xE0,
    rsa3072: 0x05,
    rsa4096: 0x16,
    x25519: 0xE1,
    secp256k1: 0x53,
    sm2: 0x54,
    secp521r1: 0x15,
  );

  List<int> encode() => [
        enabled ? 0x01 : 0x00,
        ed25519,
        rsa3072,
        rsa4096,
        x25519,
        secp256k1,
        secp521r1,
        sm2,
      ];

  Map<int, AlgorithmType> toAlgorithmMap() => {
        ed25519: AlgorithmType.ed25519,
        rsa3072: AlgorithmType.rsa3072,
        rsa4096: AlgorithmType.rsa4096,
        x25519: AlgorithmType.x25519,
        secp256k1: AlgorithmType.secp256k1,
        sm2: AlgorithmType.sm2,
        secp521r1: AlgorithmType.eccp521,
      };

  int idFor(AlgorithmType algorithm) {
    return switch (algorithm) {
      AlgorithmType.ed25519 => ed25519,
      AlgorithmType.rsa3072 => rsa3072,
      AlgorithmType.rsa4096 => rsa4096,
      AlgorithmType.x25519 => x25519,
      AlgorithmType.secp256k1 => secp256k1,
      AlgorithmType.sm2 => sm2,
      AlgorithmType.eccp521 => secp521r1,
      _ => algorithm.value,
    };
  }

  static PivAlgorithmExtensionConfig decode(List<int> data) {
    if (data.length < 7) {
      throw ArgumentError(
          'Invalid PIV algorithm extension config length: ${data.length}');
    }
    return PivAlgorithmExtensionConfig(
      enabled: data[0] != 0x00,
      ed25519: data[1],
      rsa3072: data[2],
      rsa4096: data[3],
      x25519: data[4],
      secp256k1: data[5],
      sm2: data.length >= 8 ? data[7] : data[6],
      secp521r1: data.length >= 8
          ? data[6]
          : PivAlgorithmExtensionConfig.defaults.secp521r1,
    );
  }
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

  @override
  String toString() {
    switch (this) {
      case PinPolicy.defaultPolicy:
        return S.of(Get.context!).pivPinPolicyDefault;
      case PinPolicy.never:
        return S.of(Get.context!).pivPinPolicyNever;
      case PinPolicy.once:
        return S.of(Get.context!).pivPinPolicyOnce;
      case PinPolicy.always:
        return S.of(Get.context!).pivPinPolicyAlways;
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

  @override
  String toString() {
    switch (this) {
      case TouchPolicy.defaultPolicy:
        return S.of(Get.context!).pivTouchPolicyDefault;
      case TouchPolicy.never:
        return S.of(Get.context!).pivTouchPolicyNever;
      case TouchPolicy.always:
        return S.of(Get.context!).pivTouchPolicyAlways;
      case TouchPolicy.cached:
        return S.of(Get.context!).pivTouchPolicyCached;
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
  X509CertData? cert;

  SlotInfo(
      this.number,
      this.algorithm,
      this.pinPolicy,
      this.touchPolicy,
      this.origin,
      this.public,
      this.defaultValue,
      this.retriesCount,
      this.remainingCount);

  static SlotInfo parse(
    int number,
    List<int> buf, {
    PivAlgorithmExtensionConfig algorithmExtensionConfig =
        PivAlgorithmExtensionConfig.defaults,
  }) {
    Map map = TLV.parse(buf);
    final algoId = map[0x01][0] as int;
    var algo = algorithmExtensionConfig.enabled
        ? (algorithmExtensionConfig.toAlgorithmMap()[algoId] ??
            AlgorithmType.fromValue(algoId))
        : AlgorithmType.fromValue(algoId);
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
    return SlotInfo(number, algo, pinPolicy, touchPolicy, origin, public,
        defaultValue, retriesCount, remainingCount);
  }

  @override
  String toString() {
    return 'SlotInfo{number: $number, algorithm: $algorithm, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, origin: $origin, public: $public, defaultValue: $defaultValue, retries: $remainingCount/$retriesCount}';
  }
}
