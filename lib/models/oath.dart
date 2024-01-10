enum OathVersion { legacy, v1 }

enum OathType { hotp, totp }

extension OathTypeEx on OathType {
  int toValue() {
    switch (this) {
      case OathType.hotp:
        return 0x10;
      case OathType.totp:
        return 0x20;
      default:
        return 0;
    }
  }
}

enum OathAlgorithm { sha1, sha256, sha512 }

extension AlgorithmEx on OathAlgorithm {
  int toValue() {
    switch (this) {
      case OathAlgorithm.sha1:
        return 0x01;
      case OathAlgorithm.sha256:
        return 0x02;
      case OathAlgorithm.sha512:
        return 0x03;
      default:
        return 0;
    }
  }
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
