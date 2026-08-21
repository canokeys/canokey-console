import 'dart:typed_data';

import 'package:canokey_console/helper/utils/piv_post_quantum.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the ML-DSA-65 seed-only import template', () {
    final seed = Uint8List.fromList(List<int>.generate(32, (index) => index));

    final data = PivPostQuantumProtocol.buildImportData(
      algorithm: AlgorithmType.mldsa65,
      seed: seed,
      pinPolicy: PinPolicy.once,
      touchPolicy: TouchPolicy.cached,
    );

    expect(data.sublist(0, 2), [0x09, 0x20]);
    expect(data.sublist(2, 34), seed);
    expect(data.sublist(34), [0xAA, 0x01, 0x02, 0xAB, 0x01, 0x03]);
  });

  test('builds the ML-KEM-768 d || z import template', () {
    final seed =
        Uint8List.fromList(List<int>.generate(64, (index) => 0x40 + index));

    final data = PivPostQuantumProtocol.buildImportData(
      algorithm: AlgorithmType.mlkem768,
      seed: seed,
      pinPolicy: PinPolicy.never,
      touchPolicy: TouchPolicy.always,
    );

    expect(data.sublist(0, 2), [0x0A, 0x40]);
    expect(data.sublist(2, 66), seed);
    expect(data.sublist(66), [0xAA, 0x01, 0x01, 0xAB, 0x01, 0x02]);
  });

  test('builds the chained ML-KEM-768 decapsulation payload', () {
    final ciphertext = Uint8List.fromList(List<int>.generate(
        PivPostQuantumProtocol.mlKem768CiphertextLength,
        (index) => index & 0xFF));

    final data = PivPostQuantumProtocol.buildMlKemDecapsulationData(ciphertext);

    expect(data.length, 1098);
    expect(data.sublist(0, 10),
        [0x7C, 0x82, 0x04, 0x46, 0x82, 0x00, 0x81, 0x82, 0x04, 0x40]);
    expect(data.sublist(10), ciphertext);
  });

  test('parses the wrapped ML-KEM-768 shared secret', () {
    final secret = List<int>.generate(32, (index) => 0xA0 + index);

    final parsed = PivPostQuantumProtocol.parseMlKemSharedSecret(
        [0x7C, 0x22, 0x82, 0x20, ...secret]);

    expect(parsed, secret);
  });

  test('rejects invalid post-quantum material lengths', () {
    expect(
      () => PivPostQuantumProtocol.buildImportData(
        algorithm: AlgorithmType.mldsa65,
        seed: Uint8List(31),
        pinPolicy: PinPolicy.once,
        touchPolicy: TouchPolicy.never,
      ),
      throwsArgumentError,
    );
    expect(
      () => PivPostQuantumProtocol.buildMlKemDecapsulationData(Uint8List(1087)),
      throwsArgumentError,
    );
    expect(
      () => PivPostQuantumProtocol.parseMlKemSharedSecret(
          [0x7C, 0x03, 0x82, 0x01, 0x00]),
      throwsArgumentError,
    );
  });
}
