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

enum OathCodeFormat {
  decimal,
  steam;

  static OathCodeFormat fromIssuer(String issuer) {
    return issuer.toLowerCase() == 'steam'
        ? OathCodeFormat.steam
        : OathCodeFormat.decimal;
  }
}

class OathItem {
  String issuer, account;
  OathType type = OathType.totp;
  OathCodeFormat format = OathCodeFormat.decimal;
  bool requireTouch = false;
  String code = '';
  int length = 0; // item size in bytes

  OathItem(this.issuer, this.account,
      {this.type = OathType.totp,
      OathCodeFormat? format,
      this.requireTouch = false,
      this.code = ''}) {
    this.format = format ?? OathCodeFormat.fromIssuer(issuer);
  }

  String get name => issuer == '' ? account : '$issuer:$account';

  @override
  String toString() {
    return 'OathItem{issuer: $issuer, account: $account, type: $type, format: $format, requireTouch: $requireTouch, code: $code, length: $length}';
  }
}

String formatOathCode({
  required int rawCode,
  required int digits,
  required OathCodeFormat format,
}) {
  switch (format) {
    case OathCodeFormat.decimal:
      return (rawCode % _digitsPower[digits]).toString().padLeft(digits, '0');
    case OathCodeFormat.steam:
      return formatSteamCode(rawCode);
  }
}

String formatSteamCode(int rawCode) {
  const chars = '23456789BCDFGHJKMNPQRTVWXY';
  var code = rawCode;
  final buffer = StringBuffer();
  for (var i = 0; i < 5; i++) {
    buffer.write(chars[code % chars.length]);
    code ~/= chars.length;
  }
  return buffer.toString();
}

final List<int> _digitsPower = [
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
  1000000000,
  10000000000,
  100000000000,
  1000000000000
];
