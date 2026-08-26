import 'package:canokey_console/helper/utils/piv_metadata_directory.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses version 1 key and certificate entries', () {
    final directory = PivMetadataDirectory.parse([
      0x01,
      0x01,
      0x01,
      0x02,
      18,
      0x9A,
      0x01,
      0x11,
      0x01,
      0x02,
      0x01,
      0x9C,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x82,
      0x03,
      0x14,
      0x02,
      0x03,
      0x03,
    ]);

    expect(directory.version, 1);
    expect(directory.entries, hasLength(3));
    expect(directory.entries[0].slot, 0x9A);
    expect(directory.entries[0].hasKey, isTrue);
    expect(directory.entries[0].hasCertificate, isFalse);
    expect(directory.entries[0].algorithmId, 0x11);
    expect(directory.entries[0].origin, Origin.generated);
    expect(directory.entries[0].pinPolicy, PinPolicy.once);
    expect(directory.entries[0].touchPolicy, TouchPolicy.never);
    final slot =
        directory.entries[0].toSlotInfo(PivAlgorithmExtensionConfig.defaults);
    expect(slot.algorithm, AlgorithmType.eccp256);
    expect(slot.public, isEmpty);
    expect(directory.entries[1].hasKey, isFalse);
    expect(directory.entries[1].hasCertificate, isTrue);
    expect(directory.entries[1].origin, isNull);
    expect(directory.entries[2].hasKey, isTrue);
    expect(directory.entries[2].hasCertificate, isTrue);
  });

  test('accepts the maximum single-byte directory payload length', () {
    final entries = <int>[];
    for (final slot in [
      0x9A,
      0x9C,
      0x9D,
      0x9E,
      for (var slot = 0x82; slot <= 0x95; slot++) slot,
    ]) {
      entries.addAll([slot, 0x02, 0x00, 0x00, 0x00, 0x00]);
    }

    final directory =
        PivMetadataDirectory.parse([0x01, 0x01, 0x01, 0x02, 0x90, ...entries]);

    expect(directory.entries, hasLength(24));
  });

  test('rejects unsupported directory versions', () {
    expect(
      () => PivMetadataDirectory.parse([0x01, 0x01, 0x02, 0x02, 0x00]),
      throwsUnsupportedError,
    );
  });

  test('maps configured extension algorithm IDs in lightweight slots', () {
    const config = PivAlgorithmExtensionConfig(
      enabled: true,
      ed25519: 0x40,
      rsa3072: 0x41,
      rsa4096: 0x42,
      x25519: 0x43,
      secp256k1: 0x44,
      secp521r1: 0x45,
      sm2: 0x46,
      mldsa65: 0x56,
      mlkem768: 0x57,
    );
    final directory = PivMetadataDirectory.parse([
      0x01,
      0x01,
      0x01,
      0x02,
      0x06,
      0x9A,
      0x01,
      0x56,
      0x01,
      0x02,
      0x01,
    ]);

    expect(directory.entries.single.toSlotInfo(config).algorithm,
        AlgorithmType.mldsa65);
  });

  test('rejects malformed directory entries', () {
    for (final data in [
      [0x01, 0x01, 0x01, 0x02, 0x01, 0x00],
      [0x01, 0x01, 0x01, 0x02, 0x06, 0x9A, 0x00, 0, 0, 0, 0],
      [0x01, 0x01, 0x01, 0x02, 0x06, 0x9B, 0x02, 0, 0, 0, 0],
      [0x01, 0x01, 0x01, 0x02, 0x06, 0x9A, 0x02, 1, 0, 0, 0],
    ]) {
      expect(() => PivMetadataDirectory.parse(data), throwsFormatException);
    }
  });
}
