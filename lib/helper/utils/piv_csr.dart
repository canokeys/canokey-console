import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/api/piv_crypto.dart';
import 'package:convert/convert.dart';

class PivPublicKey {
  final AlgorithmType algorithm;
  final Uint8List encodedSubjectPublicKeyInfo;
  final Uint8List? rawPublicKey;

  const PivPublicKey({
    required this.algorithm,
    required this.encodedSubjectPublicKeyInfo,
    this.rawPublicKey,
  });

  factory PivPublicKey.fromGenerateResponse(
    AlgorithmType algorithm,
    List<int> response,
  ) {
    final data = buildPivPublicKey(
      algorithm: algorithm.value,
      cardData: response,
      generatedResponse: true,
    );
    return PivPublicKey._fromRust(algorithm, data);
  }

  factory PivPublicKey.fromSlotMetadata(
    AlgorithmType algorithm,
    List<int> public,
  ) {
    final data = buildPivPublicKey(
      algorithm: algorithm.value,
      cardData: public,
      generatedResponse: false,
    );
    return PivPublicKey._fromRust(algorithm, data);
  }

  factory PivPublicKey.fromSubjectPublicKeyInfo(
    AlgorithmType algorithm,
    Uint8List subjectPublicKeyInfo,
  ) {
    return PivPublicKey._fromRust(
      algorithm,
      parsePivPublicKeyInfo(
        algorithm: algorithm.value,
        subjectPublicKeyInfo: subjectPublicKeyInfo,
      ),
    );
  }

  factory PivPublicKey._fromRust(
    AlgorithmType algorithm,
    PivPublicKeyData data,
  ) {
    return PivPublicKey(
      algorithm: algorithm,
      encodedSubjectPublicKeyInfo: data.subjectPublicKeyInfo,
      rawPublicKey: data.rawPublicKey.isEmpty
          ? null
          : Uint8List.fromList(data.rawPublicKey),
    );
  }

  String toPem() {
    final encoded = base64.encode(encodedSubjectPublicKeyInfo);
    final lines = <String>[];
    for (var offset = 0; offset < encoded.length; offset += 64) {
      final end = (offset + 64).clamp(0, encoded.length);
      lines.add(encoded.substring(offset, end));
    }
    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n'
        '-----END PUBLIC KEY-----';
  }
}

class PivCsrBuilder {
  static Uint8List buildCertificationRequestInfo({
    required Map<String, String> subject,
    required PivPublicKey publicKey,
    List<String> subjectAlternativeNames = const [],
  }) {
    return preparePivCsr(
      commonName: subject['CN'] ?? '',
      organization: subject['O'],
      organizationalUnit: subject['OU'],
      country: subject['C'],
      subjectPublicKeyInfo: publicKey.encodedSubjectPublicKeyInfo,
      subjectAlternativeNames: subjectAlternativeNames,
    );
  }

  static String buildPem({
    required Uint8List certificationRequestInfo,
    required AlgorithmType algorithm,
    required Uint8List signature,
  }) {
    return finishPivCsr(
      certificationRequestInfo: certificationRequestInfo,
      algorithm: algorithm.value,
      signature: signature,
    );
  }
}

class PivCertificateBuilder {
  static Uint8List buildTbsCertificate({
    required Map<String, String> subject,
    required PivPublicKey publicKey,
    required BigInt serialNumber,
    required DateTime notBefore,
    required DateTime notAfter,
    required List<String> subjectAlternativeNames,
  }) {
    var serialHex = serialNumber.toRadixString(16);
    if (serialHex.length.isOdd) serialHex = '0$serialHex';
    return prepareSelfSignedCertificate(
      params: SelfSignedCertificateParams(
        commonName: subject['CN'] ?? '',
        organization: subject['O'],
        organizationalUnit: subject['OU'],
        country: subject['C'],
        subjectPublicKeyInfo: publicKey.encodedSubjectPublicKeyInfo,
        serialNumber: Uint8List.fromList(hex.decode(serialHex)),
        notBefore: _x509Time(notBefore),
        notAfter: _x509Time(notAfter),
        subjectAlternativeNames: subjectAlternativeNames,
      ),
    );
  }

  static String _x509Time(DateTime value) {
    final utc = value.toUtc();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${twoDigits(utc.month)}-${twoDigits(utc.day)}T'
        '${twoDigits(utc.hour)}:${twoDigits(utc.minute)}:'
        '${twoDigits(utc.second)}Z';
  }

  static Uint8List buildCertificate({
    required Uint8List tbsCertificate,
    required AlgorithmType algorithm,
    required Uint8List signature,
  }) {
    return finishSelfSignedCertificate(
      tbsCertificate: tbsCertificate,
      algorithm: algorithm.value,
      signature: signature,
    );
  }
}
