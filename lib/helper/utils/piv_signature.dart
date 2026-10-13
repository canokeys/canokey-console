import 'dart:typed_data';

import 'package:canokey_console/helper/utils/piv_csr.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';

class PivSignatureTest {
  static PivPublicKey? publicKeyFromSlot(SlotInfo slot) {
    if (slot.public.isNotEmpty) {
      return PivPublicKey.fromSlotMetadata(slot.algorithm, slot.public);
    }
    final certBytes = slot.certBytes;
    if (certBytes != null && certBytes.isNotEmpty) {
      final cert = slot.cert ?? parseX509CertFromDer(der: certBytes);
      return PivPublicKey.fromSubjectPublicKeyInfo(
        slot.algorithm,
        cert.subjectPublicKeyInfo,
      );
    }
    return null;
  }

  static Future<bool> verify({
    required PivPublicKey publicKey,
    required Uint8List data,
    required Uint8List signature,
  }) {
    final key = switch (publicKey.algorithm) {
      AlgorithmType.rsa1024 ||
      AlgorithmType.rsa2048 ||
      AlgorithmType.rsa3072 ||
      AlgorithmType.rsa4096 =>
        publicKey.encodedSubjectPublicKeyInfo,
      AlgorithmType.eccp256 ||
      AlgorithmType.eccp384 ||
      AlgorithmType.eccp521 ||
      AlgorithmType.secp256k1 ||
      AlgorithmType.sm2 ||
      AlgorithmType.ed25519 =>
        publicKey.rawPublicKey,
      _ => throw ArgumentError(
          'Unsupported signature test algorithm: ${publicKey.algorithm}'),
    };
    if (key == null) {
      return Future.value(false);
    }
    return Future.value(verifyPivSignature(
      algorithm: publicKey.algorithm.value,
      publicKey: key,
      data: data,
      signature: signature,
    ));
  }
}
