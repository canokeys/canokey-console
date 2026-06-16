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
        );
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

    final algorithmIdentifier = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName(oidName));

    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithmIdentifier)
      ..add(ASN1BitString(stringValues: publicKey));

    return subjectPublicKeyInfo.encode();
  }

  static String _curveName(AlgorithmType algorithm) {
    switch (algorithm) {
      case AlgorithmType.eccp256:
        return 'prime256v1';
      case AlgorithmType.eccp384:
        return 'secp384r1';
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
      AlgorithmType.secp256k1 => 'ecdsaWithSHA256',
      AlgorithmType.sm2 => '1.2.156.10197.1.501',
      AlgorithmType.ed25519 => 'curveEd25519',
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

class Sm3Digest {
  static const _iv = [
    0x7380166F,
    0x4914B2B9,
    0x172442D7,
    0xDA8A0600,
    0xA96F30BC,
    0x163138AA,
    0xE38DEE4D,
    0xB0FB0E4E,
  ];

  static Uint8List digest(List<int> data) {
    final message = Uint8List.fromList(data);
    final bitLength = message.length * 8;
    final paddingLength = (56 - (message.length + 1) % 64) % 64;
    final padded = Uint8List(message.length + 1 + paddingLength + 8)
      ..setAll(0, message);
    padded[message.length] = 0x80;
    final byteData = ByteData.view(padded.buffer);
    byteData.setUint64(padded.length - 8, bitLength, Endian.big);

    final v = List<int>.from(_iv);
    for (var offset = 0; offset < padded.length; offset += 64) {
      _compress(v, padded.sublist(offset, offset + 64));
    }

    final out = Uint8List(32);
    final outData = ByteData.view(out.buffer);
    for (var i = 0; i < v.length; i++) {
      outData.setUint32(i * 4, v[i], Endian.big);
    }
    return out;
  }

  static void _compress(List<int> v, Uint8List block) {
    final blockData = ByteData.view(block.buffer, block.offsetInBytes);
    final w = List<int>.filled(68, 0);
    final w1 = List<int>.filled(64, 0);
    for (var i = 0; i < 16; i++) {
      w[i] = blockData.getUint32(i * 4, Endian.big);
    }
    for (var i = 16; i < 68; i++) {
      w[i] = _u32(_p1(w[i - 16] ^ w[i - 9] ^ _rotl(w[i - 3], 15)) ^
          _rotl(w[i - 13], 7) ^
          w[i - 6]);
    }
    for (var i = 0; i < 64; i++) {
      w1[i] = _u32(w[i] ^ w[i + 4]);
    }

    var a = v[0];
    var b = v[1];
    var c = v[2];
    var d = v[3];
    var e = v[4];
    var f = v[5];
    var g = v[6];
    var h = v[7];

    for (var j = 0; j < 64; j++) {
      final tj = j < 16 ? 0x79CC4519 : 0x7A879D8A;
      final ss1 = _rotl(_u32(_rotl(a, 12) + e + _rotl(tj, j)), 7);
      final ss2 = ss1 ^ _rotl(a, 12);
      final tt1 = _u32(_ff(a, b, c, j) + d + ss2 + w1[j]);
      final tt2 = _u32(_gg(e, f, g, j) + h + ss1 + w[j]);
      d = c;
      c = _rotl(b, 9);
      b = a;
      a = tt1;
      h = g;
      g = _rotl(f, 19);
      f = e;
      e = _p0(tt2);
    }

    v[0] = _u32(v[0] ^ a);
    v[1] = _u32(v[1] ^ b);
    v[2] = _u32(v[2] ^ c);
    v[3] = _u32(v[3] ^ d);
    v[4] = _u32(v[4] ^ e);
    v[5] = _u32(v[5] ^ f);
    v[6] = _u32(v[6] ^ g);
    v[7] = _u32(v[7] ^ h);
  }

  static int _ff(int x, int y, int z, int j) =>
      j < 16 ? (x ^ y ^ z) : ((x & y) | (x & z) | (y & z));

  static int _gg(int x, int y, int z, int j) =>
      j < 16 ? (x ^ y ^ z) : ((x & y) | (~x & z));

  static int _p0(int x) => _u32(x ^ _rotl(x, 9) ^ _rotl(x, 17));

  static int _p1(int x) => _u32(x ^ _rotl(x, 15) ^ _rotl(x, 23));

  static int _rotl(int x, int n) {
    n &= 31;
    x = _u32(x);
    return _u32((x << n) | (x >> (32 - n)));
  }

  static int _u32(int x) => x & 0xFFFFFFFF;
}
