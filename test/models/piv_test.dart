import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the recommended PIN policy for each standard PIV slot', () {
    expect(recommendedPivPinPolicy('9A'), PinPolicy.once);
    expect(recommendedPivPinPolicy('9C'), PinPolicy.always);
    expect(recommendedPivPinPolicy('9D'), PinPolicy.once);
    expect(recommendedPivPinPolicy('9E'), PinPolicy.never);
  });

  test('uses key management PIN policy for retired slots', () {
    expect(recommendedPivPinPolicy('82'), PinPolicy.once);
    expect(recommendedPivPinPolicy('95'), PinPolicy.once);
  });

  test('recognizes the post-quantum PIV algorithm IDs', () {
    expect(AlgorithmType.fromValue(0xE2), AlgorithmType.mldsa65);
    expect(AlgorithmType.fromValue(0xE3), AlgorithmType.mlkem768);
    expect(AlgorithmType.mldsa65.label, 'ML-DSA-65');
    expect(AlgorithmType.mlkem768.label, 'ML-KEM-768');
  });

  test('uses standard display names for certificate key algorithms', () {
    expect(
      [
        AlgorithmType.eccp256,
        AlgorithmType.eccp384,
        AlgorithmType.eccp521,
        AlgorithmType.secp256k1,
        AlgorithmType.sm2,
        AlgorithmType.ed25519,
        AlgorithmType.rsa2048,
        AlgorithmType.rsa3072,
        AlgorithmType.rsa4096,
      ].map((algorithm) => algorithm.label),
      [
        'ECC P-256',
        'ECC P-384',
        'ECC P-521',
        'secp256k1',
        'SM2',
        'Ed25519',
        'RSA 2048',
        'RSA 3072',
        'RSA 4096',
      ],
    );
  });

  test('round-trips post-quantum algorithm extension IDs', () {
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

    final decoded = PivAlgorithmExtensionConfig.decode(config.encode());

    expect(config.encode(),
        [0x01, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x56, 0x57]);
    expect(decoded.idFor(AlgorithmType.mldsa65), 0x56);
    expect(decoded.idFor(AlgorithmType.mlkem768), 0x57);
    expect(decoded.toAlgorithmMap()[0x56], AlgorithmType.mldsa65);
    expect(decoded.toAlgorithmMap()[0x57], AlgorithmType.mlkem768);
  });

  test('decodes old extension configs with default post-quantum IDs', () {
    final config = PivAlgorithmExtensionConfig.decode(
        [0x01, 0xE0, 0x05, 0x16, 0xE1, 0x53, 0x15, 0x54]);

    expect(config.mldsa65, 0xE2);
    expect(config.mlkem768, 0xE3);
  });
}
