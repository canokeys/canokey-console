enum OathVersion {
  legacy, // incompatible with YubiKey, no support code
  v1, // compatible with YubiKey, support code
  v2, // support two slots for HOTP
}

enum OathType {
  hotp(0x10),
  totp(0x20);

  const OathType(this.value);

  static OathType fromName(String name) {
    switch (name.toLowerCase()) {
      case 'totp':
        return OathType.totp;
      case 'hotp':
        return OathType.hotp;
      default:
        throw ArgumentError('Invalid oath type: $name');
    }
  }

  final int value;
}

enum OathAlgorithm {
  sha1(0x01),
  sha256(0x02),
  sha512(0x03);

  const OathAlgorithm(this.value);

  static OathAlgorithm fromName(String name) {
    switch (name.toUpperCase()) {
      case 'SHA1':
        return OathAlgorithm.sha1;
      case 'SHA256':
        return OathAlgorithm.sha256;
      case 'SHA512':
        return OathAlgorithm.sha512;
      default:
        throw ArgumentError('Invalid algorithm name: $name');
    }
  }

  final int value;
}

class OathItem {
  String issuer, account;
  OathType type = OathType.totp;
  bool requireTouch = false;
  String code = '';
  int length = 0; // item size in bytes

  OathItem(this.issuer, this.account,
      {this.type = OathType.totp, this.requireTouch = false, this.code = ''});

  String get name => issuer == '' ? account : '$issuer:$account';

  @override
  String toString() {
    return 'OathItem{issuer: $issuer, account: $account, type: $type, requireTouch: $requireTouch, code: $code, length: $length}';
  }
}
