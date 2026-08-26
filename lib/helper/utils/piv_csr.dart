import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_ia5_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_set.dart';
import 'package:pointycastle/asn1/primitives/asn1_utc_time.dart';
import 'package:pointycastle/asn1/pkcs/pkcs10/asn1_subject_public_key_info.dart';

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
    final responseMap = TLV.parse(response);
    final keyData = responseMap[0x7F49];
    if (keyData is! List<int>) {
      throw ArgumentError('Invalid generated public key response');
    }
    final keyMap = TLV.parse(keyData);

    switch (algorithm) {
      case AlgorithmType.rsa1024:
      case AlgorithmType.rsa2048:
      case AlgorithmType.rsa3072:
      case AlgorithmType.rsa4096:
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo: _rsaSubjectPublicKeyInfo(keyMap),
        );
      case AlgorithmType.eccp256:
      case AlgorithmType.eccp384:
      case AlgorithmType.eccp521:
      case AlgorithmType.secp256k1:
      case AlgorithmType.sm2:
        final rawPublicKey = _childOctets(keyMap, 0x86);
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo:
              _eccSubjectPublicKeyInfo(algorithm, rawPublicKey),
          rawPublicKey: rawPublicKey,
        );
      case AlgorithmType.ed25519:
        final rawPublicKey = _childOctets(keyMap, 0x86);
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo: _montgomerySubjectPublicKeyInfoFromBytes(
              rawPublicKey, 'curveEd25519'),
          rawPublicKey: rawPublicKey,
        );
      case AlgorithmType.mldsa65:
      case AlgorithmType.mlkem768:
        return _postQuantumPublicKey(algorithm, keyMap);
      case AlgorithmType.x25519:
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo:
              _montgomerySubjectPublicKeyInfo(keyMap, 'curveX25519'),
        );
      default:
        throw ArgumentError('Unsupported generated key algorithm: $algorithm');
    }
  }

  factory PivPublicKey.fromSlotMetadata(
    AlgorithmType algorithm,
    List<int> public,
  ) {
    final keyMap = TLV.parse(public);
    switch (algorithm) {
      case AlgorithmType.rsa1024:
      case AlgorithmType.rsa2048:
      case AlgorithmType.rsa3072:
      case AlgorithmType.rsa4096:
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo: _rsaSubjectPublicKeyInfo(keyMap),
        );
      case AlgorithmType.eccp256:
      case AlgorithmType.eccp384:
      case AlgorithmType.eccp521:
      case AlgorithmType.secp256k1:
      case AlgorithmType.sm2:
        final rawPublicKey = _childOctets(keyMap, 0x86);
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo:
              _eccSubjectPublicKeyInfo(algorithm, rawPublicKey),
          rawPublicKey: rawPublicKey,
        );
      case AlgorithmType.ed25519:
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo: _ed25519SubjectPublicKeyInfo(keyMap),
          rawPublicKey: _childOctets(keyMap, 0x86),
        );
      case AlgorithmType.x25519:
        return PivPublicKey(
          algorithm: algorithm,
          encodedSubjectPublicKeyInfo:
              _montgomerySubjectPublicKeyInfo(keyMap, 'curveX25519'),
          rawPublicKey: _childOctets(keyMap, 0x86),
        );
      case AlgorithmType.mldsa65:
      case AlgorithmType.mlkem768:
        return _postQuantumPublicKey(algorithm, keyMap);
      default:
        throw ArgumentError('Unsupported public key algorithm: $algorithm');
    }
  }

  factory PivPublicKey.fromSubjectPublicKeyInfo(
    AlgorithmType algorithm,
    Uint8List subjectPublicKeyInfo,
  ) {
    final spki = ASN1SubjectPublicKeyInfo.fromSequence(
        ASN1Sequence.fromBytes(subjectPublicKeyInfo));
    final rawPublicKey =
        Uint8List.fromList(spki.subjectPublicKey.stringValues ?? const <int>[]);
    return PivPublicKey(
      algorithm: algorithm,
      encodedSubjectPublicKeyInfo: subjectPublicKeyInfo,
      rawPublicKey: rawPublicKey,
    );
  }

  String toPem() {
    final encoded = base64.encode(encodedSubjectPublicKeyInfo);
    return '-----BEGIN PUBLIC KEY-----\n'
        '${StringUtils.chunk(encoded, 64).join('\n')}\n'
        '-----END PUBLIC KEY-----';
  }

  static Uint8List _rsaSubjectPublicKeyInfo(Map keyMap) {
    final modulus = _childOctets(keyMap, 0x81);
    final exponent = _childOctets(keyMap, 0x82);

    final publicKey = ASN1Sequence()
      ..add(ASN1Integer(_unsignedBigInt(modulus)))
      ..add(ASN1Integer(_unsignedBigInt(exponent)));

    final algorithm = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
      ..add(ASN1Null());

    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithm)
      ..add(ASN1BitString(stringValues: publicKey.encode()));

    return subjectPublicKeyInfo.encode();
  }

  static Uint8List _eccSubjectPublicKeyInfo(
      AlgorithmType algorithm, Uint8List point) {
    final algorithmIdentifier = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('ecPublicKey'))
      ..add(_objectIdentifier(_curveName(algorithm)));

    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithmIdentifier)
      ..add(ASN1BitString(stringValues: point));

    return subjectPublicKeyInfo.encode();
  }

  static Uint8List _ed25519SubjectPublicKeyInfo(Map keyMap) {
    return _montgomerySubjectPublicKeyInfo(keyMap, 'curveEd25519');
  }

  static Uint8List _montgomerySubjectPublicKeyInfo(Map keyMap, String oidName) {
    final publicKey = _childOctets(keyMap, 0x86);
    return _montgomerySubjectPublicKeyInfoFromBytes(publicKey, oidName);
  }

  static Uint8List _montgomerySubjectPublicKeyInfoFromBytes(
      Uint8List publicKey, String oidName) {
    final algorithmIdentifier = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName(oidName));

    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithmIdentifier)
      ..add(ASN1BitString(stringValues: publicKey));

    return subjectPublicKeyInfo.encode();
  }

  static PivPublicKey _postQuantumPublicKey(
      AlgorithmType algorithm, Map keyMap) {
    final publicKey = _childOctets(keyMap, 0x86);
    final oid = switch (algorithm) {
      AlgorithmType.mldsa65 => '2.16.840.1.101.3.4.3.18',
      AlgorithmType.mlkem768 => '2.16.840.1.101.3.4.4.2',
      _ =>
        throw ArgumentError('Unsupported post-quantum algorithm: $algorithm'),
    };
    final algorithmIdentifier = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromIdentifierString(oid));
    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithmIdentifier)
      ..add(ASN1BitString(stringValues: publicKey));
    return PivPublicKey(
      algorithm: algorithm,
      encodedSubjectPublicKeyInfo: subjectPublicKeyInfo.encode(),
      rawPublicKey: publicKey,
    );
  }

  static String _curveName(AlgorithmType algorithm) {
    switch (algorithm) {
      case AlgorithmType.eccp256:
        return 'prime256v1';
      case AlgorithmType.eccp384:
        return 'secp384r1';
      case AlgorithmType.eccp521:
        return '1.3.132.0.35';
      case AlgorithmType.secp256k1:
        return 'secp256k1';
      case AlgorithmType.sm2:
        return '1.2.156.10197.1.301';
      default:
        throw ArgumentError('Unsupported EC algorithm: $algorithm');
    }
  }

  static ASN1ObjectIdentifier _objectIdentifier(String nameOrOid) {
    if (RegExp(r'^\d+(\.\d+)+$').hasMatch(nameOrOid)) {
      return ASN1ObjectIdentifier.fromIdentifierString(nameOrOid);
    }
    return ASN1ObjectIdentifier.fromName(nameOrOid);
  }

  static Uint8List _childOctets(Map keyMap, int tag) {
    final value = keyMap[tag];
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }
    throw ArgumentError('Missing public key tag ${tag.toRadixString(16)}');
  }

  static BigInt _unsignedBigInt(Uint8List bytes) {
    return BigInt.parse(hex.encode(bytes), radix: 16);
  }
}

class PivCsrBuilder {
  static Uint8List buildCertificationRequestInfo({
    required Map<String, String> subject,
    required PivPublicKey publicKey,
    List<String> subjectAlternativeNames = const [],
  }) {
    final info = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero))
      ..add(X509Utils.encodeDN(subject))
      ..add(ASN1Sequence.fromBytes(publicKey.encodedSubjectPublicKeyInfo))
      ..add(_buildAttributes(subjectAlternativeNames));

    return info.encode();
  }

  static String buildPem({
    required Uint8List certificationRequestInfo,
    required AlgorithmType algorithm,
    required Uint8List signature,
  }) {
    final request = ASN1Sequence()
      ..add(ASN1Sequence.fromBytes(certificationRequestInfo))
      ..add(signatureAlgorithm(algorithm))
      ..add(ASN1BitString(
          stringValues: normalizeSignature(algorithm, signature)));

    final encoded = base64.encode(request.encode());
    return '${X509Utils.BEGIN_CSR}\n${StringUtils.chunk(encoded, 64).join('\n')}\n${X509Utils.END_CSR}';
  }

  static ASN1Object _buildAttributes(List<String> subjectAlternativeNames) {
    if (subjectAlternativeNames.isEmpty) {
      return ASN1Null(tag: 0xA0);
    }

    final sanSequence = ASN1Sequence();
    for (final san in subjectAlternativeNames) {
      sanSequence.add(ASN1IA5String(stringValue: san, tag: 0x82));
    }

    final sanExtension = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('subjectAltName'))
      ..add(ASN1OctetString(octets: sanSequence.encode()));

    final extensions = ASN1Sequence()..add(sanExtension);
    final extensionSet = ASN1Set()..add(extensions);
    final extensionRequest = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('extensionRequest'))
      ..add(extensionSet);

    return ASN1OctetString(octets: extensionRequest.encode(), tag: 0xA0);
  }

  static ASN1Sequence signatureAlgorithm(AlgorithmType algorithm) {
    final oid = switch (algorithm) {
      AlgorithmType.rsa1024 ||
      AlgorithmType.rsa2048 ||
      AlgorithmType.rsa3072 ||
      AlgorithmType.rsa4096 =>
        'sha256WithRSAEncryption',
      AlgorithmType.eccp256 => 'ecdsaWithSHA256',
      AlgorithmType.eccp384 => 'ecdsaWithSHA384',
      AlgorithmType.eccp521 => 'ecdsaWithSHA512',
      AlgorithmType.secp256k1 => 'ecdsaWithSHA256',
      AlgorithmType.sm2 => '1.2.156.10197.1.501',
      AlgorithmType.ed25519 => 'curveEd25519',
      AlgorithmType.mldsa65 => '2.16.840.1.101.3.4.3.18',
      _ => throw ArgumentError('Unsupported CSR algorithm: $algorithm'),
    };

    final sequence = ASN1Sequence()..add(_objectIdentifier(oid));
    if (algorithm == AlgorithmType.rsa1024 ||
        algorithm == AlgorithmType.rsa2048 ||
        algorithm == AlgorithmType.rsa3072 ||
        algorithm == AlgorithmType.rsa4096) {
      sequence.add(ASN1Null());
    }
    return sequence;
  }

  static Uint8List normalizeSignature(
      AlgorithmType algorithm, Uint8List signature) {
    if (algorithm == AlgorithmType.eccp256 ||
        algorithm == AlgorithmType.eccp384 ||
        algorithm == AlgorithmType.eccp521 ||
        algorithm == AlgorithmType.secp256k1 ||
        algorithm == AlgorithmType.sm2) {
      if (signature.isNotEmpty && signature.first == 0x30) {
        return signature;
      }
      final half = signature.length ~/ 2;
      if (signature.length.isEven && half > 0) {
        return (ASN1Sequence()
              ..add(ASN1Integer(_unsignedBigInt(signature.sublist(0, half))))
              ..add(ASN1Integer(_unsignedBigInt(signature.sublist(half)))))
            .encode();
      }
    }
    return signature;
  }

  static BigInt _unsignedBigInt(Uint8List bytes) {
    return BigInt.parse(hex.encode(bytes), radix: 16);
  }

  static ASN1ObjectIdentifier _objectIdentifier(String nameOrOid) {
    if (RegExp(r'^\d+(\.\d+)+$').hasMatch(nameOrOid)) {
      return ASN1ObjectIdentifier.fromIdentifierString(nameOrOid);
    }
    return ASN1ObjectIdentifier.fromName(nameOrOid);
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
    final encodedSubject = X509Utils.encodeDN(subject);
    final validity = ASN1Sequence()
      ..add(ASN1UtcTime(notBefore.toUtc()))
      ..add(ASN1UtcTime(notAfter.toUtc()));

    final tbs = ASN1Sequence()
      ..add(_taggedObject(0xA0, ASN1Integer(BigInt.two).encode()))
      ..add(ASN1Integer(serialNumber))
      ..add(_signatureAlgorithm(publicKey.algorithm))
      ..add(encodedSubject)
      ..add(validity)
      ..add(X509Utils.encodeDN(subject))
      ..add(ASN1Sequence.fromBytes(publicKey.encodedSubjectPublicKeyInfo));

    final extensions = _buildExtensions(subjectAlternativeNames);
    if (extensions != null) {
      tbs.add(_taggedObject(0xA3, extensions.encode()));
    }

    return tbs.encode();
  }

  static Uint8List buildCertificate({
    required Uint8List tbsCertificate,
    required AlgorithmType algorithm,
    required Uint8List signature,
  }) {
    final certificate = ASN1Sequence()
      ..add(ASN1Sequence.fromBytes(tbsCertificate))
      ..add(_signatureAlgorithm(algorithm))
      ..add(ASN1BitString(
          stringValues:
              PivCsrBuilder.normalizeSignature(algorithm, signature)));
    return certificate.encode();
  }

  static ASN1Sequence? _buildExtensions(List<String> subjectAlternativeNames) {
    if (subjectAlternativeNames.isEmpty) {
      return null;
    }

    final sanSequence = ASN1Sequence();
    for (final san in subjectAlternativeNames) {
      sanSequence.add(ASN1IA5String(stringValue: san, tag: 0x82));
    }

    final sanExtension = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('subjectAltName'))
      ..add(ASN1OctetString(octets: sanSequence.encode()));

    return ASN1Sequence()..add(sanExtension);
  }

  static ASN1Sequence _signatureAlgorithm(AlgorithmType algorithm) {
    return PivCsrBuilder.signatureAlgorithm(algorithm);
  }

  static ASN1Object _taggedObject(int tag, Uint8List value) {
    final object = ASN1Object(tag: tag);
    object.valueBytes = value;
    object.valueByteLength = value.length;
    return object;
  }
}
