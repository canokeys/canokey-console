import 'package:canokey_console/generated/l10n.dart';
import 'package:get/get.dart';

enum OpenPgpKeyType {
  signature('Signature', 0xD6),
  encryption('Encryption', 0xD7),
  authentication('Authentication', 0xD8);

  const OpenPgpKeyType(this.name, this.uifTag);

  final String name;
  final int uifTag;

  String get label {
    switch (this) {
      case OpenPgpKeyType.signature:
        return S.of(Get.context!).openpgpSignature;
      case OpenPgpKeyType.encryption:
        return S.of(Get.context!).openpgpEncryption;
      case OpenPgpKeyType.authentication:
        return S.of(Get.context!).openpgpAuthentication;
    }
  }
}

enum OpenPgpTouchPolicy {
  off(0x00),
  on(0x01),
  permanent(0x02),
  cached(0x03),
  cachedPermanent(0x04);

  const OpenPgpTouchPolicy(this.value);

  final int value;

  static OpenPgpTouchPolicy fromValue(int value) {
    switch (value) {
      case 0x00:
        return OpenPgpTouchPolicy.off;
      case 0x01:
        return OpenPgpTouchPolicy.on;
      case 0x02:
        return OpenPgpTouchPolicy.permanent;
      case 0x03:
        return OpenPgpTouchPolicy.cached;
      case 0x04:
        return OpenPgpTouchPolicy.cachedPermanent;
      default:
        return OpenPgpTouchPolicy.off;
    }
  }

  static List<OpenPgpTouchPolicy> get writableValues => [off, on, permanent];

  String get label {
    switch (this) {
      case OpenPgpTouchPolicy.off:
        return S.of(Get.context!).openpgpUifOff;
      case OpenPgpTouchPolicy.on:
        return S.of(Get.context!).openpgpUifOn;
      case OpenPgpTouchPolicy.permanent:
        return S.of(Get.context!).openpgpUifPermanent;
      case OpenPgpTouchPolicy.cached:
        return 'Cached';
      case OpenPgpTouchPolicy.cachedPermanent:
        return 'Cached (Permanent)';
    }
  }
}

class OpenPgpKeySlotInfo {
  final OpenPgpKeyType type;
  final String? fingerprint;
  final DateTime? generatedAt;
  final OpenPgpTouchPolicy touchPolicy;
  final bool touchFixed;

  const OpenPgpKeySlotInfo({
    required this.type,
    required this.fingerprint,
    required this.generatedAt,
    required this.touchPolicy,
    required this.touchFixed,
  });

  bool get hasKey => fingerprint != null && fingerprint!.isNotEmpty;
}

class OpenPgpPinState {
  final bool signaturePinForced;
  final int? userRetries;
  final int? resetRetries;
  final int? adminRetries;

  const OpenPgpPinState({
    required this.signaturePinForced,
    required this.userRetries,
    required this.resetRetries,
    required this.adminRetries,
  });
}

class OpenPgpCardInfo {
  final String version;
  final String manufacturer;
  final String serialNumber;
  final String cardHolder;
  final String publicKeyUrl;
  final OpenPgpPinState pinState;
  final Map<OpenPgpKeyType, OpenPgpKeySlotInfo> keySlots;
  final int? touchCacheTime;

  const OpenPgpCardInfo({
    required this.version,
    required this.manufacturer,
    required this.serialNumber,
    required this.cardHolder,
    required this.publicKeyUrl,
    required this.pinState,
    required this.keySlots,
    required this.touchCacheTime,
  });
}
