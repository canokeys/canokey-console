import 'package:canokey_console/helper/utils/piv_signature.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the configured Ed25519 ID through the classic size limit', () {
    expect(
      PivSignatureProtocol.generalAuthenticateAlgorithmId(
        algorithm: AlgorithmType.ed25519,
        messageLength: PivSignatureProtocol.classicEd25519MaxMessageLength,
        config: PivAlgorithmExtensionConfig.legacyV2,
      ),
      PivAlgorithmExtensionConfig.legacyV2.ed25519,
    );
  });

  test('uses randomized Ed25519 mode for messages over the classic limit', () {
    expect(
      PivSignatureProtocol.generalAuthenticateAlgorithmId(
        algorithm: AlgorithmType.ed25519,
        messageLength: PivSignatureProtocol.classicEd25519MaxMessageLength + 1,
        config: PivAlgorithmExtensionConfig.legacyV2,
      ),
      PivSignatureProtocol.randomizedEd25519AlgorithmId,
    );
  });

  test('requires algorithm extensions for randomized Ed25519 mode', () {
    final disabled = PivAlgorithmExtensionConfig(
      enabled: false,
      ed25519: PivAlgorithmExtensionConfig.defaults.ed25519,
      rsa3072: PivAlgorithmExtensionConfig.defaults.rsa3072,
      rsa4096: PivAlgorithmExtensionConfig.defaults.rsa4096,
      x25519: PivAlgorithmExtensionConfig.defaults.x25519,
      secp256k1: PivAlgorithmExtensionConfig.defaults.secp256k1,
      sm2: PivAlgorithmExtensionConfig.defaults.sm2,
      secp521r1: PivAlgorithmExtensionConfig.defaults.secp521r1,
      mldsa65: PivAlgorithmExtensionConfig.defaults.mldsa65,
      mlkem768: PivAlgorithmExtensionConfig.defaults.mlkem768,
    );

    expect(
      () => PivSignatureProtocol.generalAuthenticateAlgorithmId(
        algorithm: AlgorithmType.ed25519,
        messageLength: PivSignatureProtocol.classicEd25519MaxMessageLength + 1,
        config: disabled,
      ),
      throwsUnsupportedError,
    );
  });

  test('keeps configured IDs for algorithms without a split signing mode', () {
    expect(
      PivSignatureProtocol.generalAuthenticateAlgorithmId(
        algorithm: AlgorithmType.mldsa65,
        messageLength: 4096,
        config: PivAlgorithmExtensionConfig.defaults,
      ),
      PivAlgorithmExtensionConfig.defaults.mldsa65,
    );
  });
}
