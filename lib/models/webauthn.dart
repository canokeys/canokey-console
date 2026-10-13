import 'dart:typed_data';

class WebAuthnSm2Config {
  final bool enabled;
  final int curveId;
  final int algoId;
  final bool canChangeEnabled;
  final Endian legacyEndian;

  const WebAuthnSm2Config({
    required this.enabled,
    required this.curveId,
    required this.algoId,
    this.canChangeEnabled = true,
    this.legacyEndian = Endian.big,
  });

  factory WebAuthnSm2Config.decode(
    List<int> bytes, {
    Endian legacyEndian = Endian.big,
  }) {
    if (bytes.length != 8 && bytes.length != 9) {
      throw const FormatException('Invalid WebAuthn SM2 configuration length');
    }
    final legacy = bytes.length == 9;
    if (legacy && bytes[0] != 0 && bytes[0] != 1) {
      throw const FormatException('Invalid WebAuthn SM2 enabled flag');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final offset = legacy ? 1 : 0;
    return WebAuthnSm2Config(
      enabled: !legacy || bytes[0] == 1,
      curveId: data.getInt32(offset, legacy ? legacyEndian : Endian.big),
      algoId: data.getInt32(offset + 4, legacy ? legacyEndian : Endian.big),
      canChangeEnabled: legacy,
      legacyEndian: legacyEndian,
    );
  }

  static bool isInt32(int value) => value >= -2147483648 && value <= 2147483647;

  static bool isValidCurveId(int value) =>
      value != 0 &&
      !(value >= 1 && value <= 8) &&
      !(value >= 256 && value <= 259);

  static bool isValidAlgorithmId(int value) => !{-7, -8, -49}.contains(value);

  Uint8List encode({
    required bool enabled,
    required int curveId,
    required int algoId,
  }) {
    if (!isInt32(curveId) ||
        !isInt32(algoId) ||
        (!canChangeEnabled &&
            (!isValidCurveId(curveId) || !isValidAlgorithmId(algoId)))) {
      throw ArgumentError('Invalid WebAuthn SM2 identifiers');
    }
    final data = ByteData(canChangeEnabled ? 9 : 8);
    final offset = canChangeEnabled ? 1 : 0;
    if (canChangeEnabled) data.setUint8(0, enabled ? 1 : 0);
    data.setInt32(
      offset,
      curveId,
      canChangeEnabled ? legacyEndian : Endian.big,
    );
    data.setInt32(
      offset + 4,
      algoId,
      canChangeEnabled ? legacyEndian : Endian.big,
    );
    return data.buffer.asUint8List();
  }
}

class WebAuthnItem {
  String rpId;
  String userName;
  String userDisplayName;
  List<int> userId;
  Uint8List credentialId;

  WebAuthnItem({
    required this.rpId,
    required this.userName,
    required this.userDisplayName,
    required this.userId,
    required this.credentialId,
  });
}
