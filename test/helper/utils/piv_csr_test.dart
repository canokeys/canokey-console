import 'dart:typed_data';

import 'package:canokey_console/helper/utils/piv_csr.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';

void main() {
  for (final testCase in [
    (
      algorithm: AlgorithmType.mldsa65,
      publicKeyLength: 1952,
      oid: '2.16.840.1.101.3.4.3.18',
    ),
    (
      algorithm: AlgorithmType.mlkem768,
      publicKeyLength: 1184,
      oid: '2.16.840.1.101.3.4.4.2',
    ),
  ]) {
    test('encodes ${testCase.algorithm.label} card responses as standard SPKI',
        () {
      final rawPublicKey = Uint8List.fromList(List<int>.generate(
          testCase.publicKeyLength, (index) => index & 0xFF));
      final publicKey = PivPublicKey.fromSlotMetadata(
        testCase.algorithm,
        _publicKeyTlv(rawPublicKey),
      );
      final generatedPublicKey = PivPublicKey.fromGenerateResponse(
        testCase.algorithm,
        _generateResponse(rawPublicKey),
      );

      expect(publicKey.rawPublicKey, rawPublicKey);
      expect(generatedPublicKey.rawPublicKey, rawPublicKey);
      expect(generatedPublicKey.encodedSubjectPublicKeyInfo,
          publicKey.encodedSubjectPublicKeyInfo);
      final spki =
          ASN1Sequence.fromBytes(publicKey.encodedSubjectPublicKeyInfo);
      final identifier = spki.elements![0] as ASN1Sequence;
      final oid = identifier.elements![0] as ASN1ObjectIdentifier;
      final bitString = spki.elements![1] as ASN1BitString;
      expect(oid.objectIdentifierAsString, testCase.oid);
      expect(bitString.stringValues, rawPublicKey);
    });
  }

  test('uses the standard ML-DSA-65 signature algorithm identifier', () {
    final identifier = PivCsrBuilder.signatureAlgorithm(AlgorithmType.mldsa65);
    final oid = identifier.elements!.single as ASN1ObjectIdentifier;

    expect(oid.objectIdentifierAsString, '2.16.840.1.101.3.4.3.18');
  });

  test('builds an ML-DSA-65 certificate within the slot limit', () {
    final publicKey = PivPublicKey.fromSlotMetadata(
      AlgorithmType.mldsa65,
      _publicKeyTlv(Uint8List(1952)),
    );
    final tbs = PivCertificateBuilder.buildTbsCertificate(
      subject: const {'CN': 'ML-DSA-65'},
      publicKey: publicKey,
      serialNumber: BigInt.one,
      notBefore: DateTime.utc(2026),
      notAfter: DateTime.utc(2027),
      subjectAlternativeNames: const [],
    );
    final certificate = PivCertificateBuilder.buildCertificate(
      tbsCertificate: tbs,
      algorithm: AlgorithmType.mldsa65,
      signature: Uint8List(3309),
    );

    // The PIV certificate object adds 13 bytes around the DER certificate,
    // leaving 6131 bytes in the card's 6144-byte object.
    expect(certificate.length, inInclusiveRange(5000, 6131));
    final parsed = ASN1Sequence.fromBytes(certificate);
    final identifier = parsed.elements![1] as ASN1Sequence;
    final oid = identifier.elements!.single as ASN1ObjectIdentifier;
    expect(oid.objectIdentifierAsString, '2.16.840.1.101.3.4.3.18');
  });
}

List<int> _publicKeyTlv(Uint8List publicKey) => [
      0x86,
      0x82,
      publicKey.length >> 8,
      publicKey.length & 0xFF,
      ...publicKey,
    ];

List<int> _generateResponse(Uint8List publicKey) {
  final key = _publicKeyTlv(publicKey);
  return [
    0x7F,
    0x49,
    0x82,
    key.length >> 8,
    key.length & 0xFF,
    ...key,
  ];
}
