import 'dart:typed_data';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/models/piv.dart';

class PivPostQuantumProtocol {
  static const int mlDsa65SeedLength = 32;
  static const int mlDsa65PublicKeyLength = 1952;
  static const int mlDsa65SignatureLength = 3309;
  static const int mlKem768SeedLength = 64;
  static const int mlKem768PublicKeyLength = 1184;
  static const int mlKem768CiphertextLength = 1088;
  static const int mlKem768SharedSecretLength = 32;

  static Uint8List buildImportData({
    required AlgorithmType algorithm,
    required Uint8List seed,
    required PinPolicy pinPolicy,
    required TouchPolicy touchPolicy,
  }) {
    final (tag, expectedLength) = switch (algorithm) {
      AlgorithmType.mldsa65 => (0x09, mlDsa65SeedLength),
      AlgorithmType.mlkem768 => (0x0A, mlKem768SeedLength),
      _ =>
        throw ArgumentError('Unsupported post-quantum algorithm: $algorithm'),
    };
    if (seed.length != expectedLength) {
      throw ArgumentError(
          '${algorithm.label} seed must be $expectedLength bytes');
    }
    return Uint8List.fromList([
      tag,
      expectedLength,
      ...seed,
      0xAA,
      0x01,
      pinPolicy.value,
      0xAB,
      0x01,
      touchPolicy.value,
    ]);
  }

  static Uint8List buildMlKemDecapsulationData(Uint8List ciphertext) {
    if (ciphertext.length != mlKem768CiphertextLength) {
      throw ArgumentError(
          'ML-KEM-768 ciphertext must be $mlKem768CiphertextLength bytes');
    }
    return Uint8List.fromList([
      0x7C,
      0x82,
      0x04,
      0x46,
      0x82,
      0x00,
      0x81,
      0x82,
      0x04,
      0x40,
      ...ciphertext,
    ]);
  }

  static Uint8List parseMlKemSharedSecret(List<int> response) {
    final outer = TLV.parse(response);
    final wrapped = outer[0x7C];
    if (wrapped is! List<int>) {
      throw ArgumentError('Invalid ML-KEM-768 response');
    }
    final inner = TLV.parse(wrapped);
    final secret = inner[0x82];
    if (secret is! List<int> || secret.length != mlKem768SharedSecretLength) {
      throw ArgumentError('Invalid ML-KEM-768 shared secret');
    }
    return Uint8List.fromList(secret);
  }
}
