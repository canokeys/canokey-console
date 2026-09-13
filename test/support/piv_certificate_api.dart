import 'dart:typed_data';

import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';

/// Parsed certificate fixture; crypto decoding is outside these UI/controller tests.
class PivCertificateApi implements RustLibApi {
  PivCertificateApi({
    String algorithm = '1.2.840.113549.1.1.1',
    int bits = 2048,
  }) : certificate = X509CertData(
         bytes: Uint8List.fromList([0x30, 0x01, 0x00]),
         subject: 'CN=Test',
         issuer: 'CN=CA',
         notBefore: '2026-01-01',
         notAfter: '2027-01-01',
         serialNumber: '01',
         signatureAlgorithm: '1.2.840.113549.1.1.11',
         signatureValue: Uint8List(0),
         publicKeyAlgorithm: algorithm,
         publicKeySize: BigInt.from(bits),
         subjectPublicKeyInfo: Uint8List.fromList([
           0x30,
           0x03,
           0x02,
           0x01,
           0x01,
         ]),
         rawPublicKey: Uint8List(0),
       );

  final X509CertData certificate;

  @override
  X509CertData crateApiCryptoParseX509CertFromDer({required List<int> der}) =>
      certificate;

  @override
  Uint8List crateApiCryptoSha256Digest({required List<int> data}) =>
      Uint8List(32);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
