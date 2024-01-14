enum OathVersion {
  legacy, // incompatible with YubiKey, no support code
  v1, // compatible with YubiKey, support code
  v2, // support two slots for HOTP
}

enum OathType {
  hotp(0x10),
  totp(0x20);

  const OathType(this.value);

  final int value;
}

enum OathAlgorithm {
  sha1(0x01),
  sha256(0x02),
  sha512(0x03);

  const OathAlgorithm(this.value);

  final int value;
}

class OathItem {
  String issuer, account;
  OathType type = OathType.totp;
  bool requireTouch = false;
  String code = '';
  int length = 0; // item size in bytes

  OathItem(this.issuer, this.account, {this.type = OathType.totp, this.requireTouch = false, this.code = ''});

  String get name => issuer == '' ? account : '$issuer:$account';
}
