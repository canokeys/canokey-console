import 'dart:typed_data';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:convert/convert.dart';

class PivManagementKeyProtocol {
  const PivManagementKeyProtocol._();

  static int blockLength(AlgorithmType algorithm) => switch (algorithm) {
        AlgorithmType.tdes => 8,
        AlgorithmType.aes192 => 16,
        _ => throw ArgumentError(
            'Unsupported management key algorithm: $algorithm'),
      };

  static String authenticateRequest(AlgorithmType algorithm) {
    return '0087${_byteHex(algorithm.value)}9B047C028100';
  }

  static Uint8List parseChallenge(List<int> response, AlgorithmType algorithm) {
    final outer = TLV.parse(response);
    final wrapped = outer[0x7C];
    if (wrapped is! List<int>) {
      throw FormatException('Invalid management key challenge');
    }
    final inner = TLV.parse(wrapped);
    final challenge = inner[0x81];
    if (challenge is! List<int> || challenge.length != blockLength(algorithm)) {
      throw FormatException('Invalid management key challenge length');
    }
    return Uint8List.fromList(challenge);
  }

  static Uint8List encryptChallenge({
    required AlgorithmType algorithm,
    required List<int> key,
    required List<int> challenge,
  }) {
    if (key.length != 24) {
      throw ArgumentError('Management key must be 24 bytes');
    }
    if (challenge.length != blockLength(algorithm)) {
      throw ArgumentError('Invalid management key challenge length');
    }
    return encryptPivManagementKeyChallenge(
      algorithm: algorithm.value,
      key: key,
      challenge: challenge,
    );
  }

  static String authenticateResponse(
      AlgorithmType algorithm, List<int> encryptedChallenge) {
    if (encryptedChallenge.length != blockLength(algorithm)) {
      throw ArgumentError('Invalid encrypted challenge length');
    }
    final inner =
        '82${_byteHex(encryptedChallenge.length)}${hex.encode(encryptedChallenge).toUpperCase()}';
    final data = '7C${_byteHex(inner.length ~/ 2)}$inner';
    return '0087${_byteHex(algorithm.value)}9B${_byteHex(data.length ~/ 2)}$data';
  }

  static String setManagementKey({
    required AlgorithmType algorithm,
    required String key,
    required TouchPolicy touchPolicy,
  }) {
    if (key.length != 48 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) {
      throw ArgumentError('Management key must be 24 bytes of hex');
    }
    blockLength(algorithm);
    final p2 =
        algorithm == AlgorithmType.aes192 && touchPolicy == TouchPolicy.always
            ? 'FE'
            : 'FF';
    return '00FFFF${p2}1B${_byteHex(algorithm.value)}9B18${key.toUpperCase()}';
  }

  static String _byteHex(int value) =>
      value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
