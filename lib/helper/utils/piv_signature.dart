import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:canokey_console/helper/utils/piv_csr.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/pkcs/pkcs10/asn1_subject_public_key_info.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha384.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as ecc_fp;
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/signers/rsa_signer.dart';

class PivSignatureTest {
  static PivPublicKey? publicKeyFromSlot(SlotInfo slot) {
    if (slot.public.isNotEmpty) {
      return PivPublicKey.fromSlotMetadata(slot.algorithm, slot.public);
    }
    final certBytes = slot.certBytes;
    if (certBytes != null && certBytes.isNotEmpty) {
      return PivPublicKey.fromSubjectPublicKeyInfo(
        slot.algorithm,
        subjectPublicKeyInfoFromCertificate(certBytes),
      );
    }
    return null;
  }

  static Uint8List subjectPublicKeyInfoFromCertificate(List<int> certBytes) {
    final cert = ASN1Sequence.fromBytes(Uint8List.fromList(certBytes));
    final tbs = cert.elements![0] as ASN1Sequence;
    var index = 0;
    if (tbs.elements![index].tag == 0xA0) {
      index++;
    }
    index += 5;
    final spki = tbs.elements![index] as ASN1Sequence;
    return spki.encode();
  }

  static Future<bool> verify({
    required PivPublicKey publicKey,
    required Uint8List data,
    required Uint8List signature,
  }) async {
    switch (publicKey.algorithm) {
      case AlgorithmType.rsa1024:
      case AlgorithmType.rsa2048:
      case AlgorithmType.rsa3072:
      case AlgorithmType.rsa4096:
        return _verifyRsa(publicKey, data, signature);
      case AlgorithmType.eccp256:
      case AlgorithmType.eccp384:
      case AlgorithmType.eccp521:
      case AlgorithmType.secp256k1:
        return _verifyEcdsa(publicKey, data, signature);
      case AlgorithmType.sm2:
        return _verifySm2(publicKey, data, signature);
      case AlgorithmType.ed25519:
        return _verifyEd25519(publicKey, data, signature);
      default:
        throw ArgumentError(
            'Unsupported signature test algorithm: ${publicKey.algorithm}');
    }
  }

  static bool _verifyRsa(
      PivPublicKey publicKey, Uint8List data, Uint8List signature) {
    final rsaKey = _rsaPublicKey(publicKey.encodedSubjectPublicKeyInfo);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(false, PublicKeyParameter<RSAPublicKey>(rsaKey));
    return signer.verifySignature(data, RSASignature(signature));
  }

  static bool _verifyEcdsa(
      PivPublicKey publicKey, Uint8List data, Uint8List signature) {
    final params = _ecDomainParameters(publicKey.algorithm);
    final rawKey = publicKey.rawPublicKey;
    if (rawKey == null) {
      return false;
    }
    final q = params.curve.decodePoint(rawKey);
    if (q == null) {
      return false;
    }
    final signer = ECDSASigner(_ecDigest(publicKey.algorithm))
      ..init(false, PublicKeyParameter<ECPublicKey>(ECPublicKey(q, params)));
    return signer.verifySignature(
        data,
        _ecSignatureFromDer(
            PivCsrBuilder.normalizeSignature(publicKey.algorithm, signature)));
  }

  static bool _verifySm2(
      PivPublicKey publicKey, Uint8List data, Uint8List signature) {
    final params = PivSm2.domainParameters;
    final rawKey = publicKey.rawPublicKey;
    if (rawKey == null) {
      return false;
    }
    final q = params.curve.decodePoint(rawKey);
    if (q == null) {
      return false;
    }
    final digest = PivSm2.digest(data, rawKey);
    final sig = _ecSignatureFromDer(
        PivCsrBuilder.normalizeSignature(publicKey.algorithm, signature));
    final n = params.n;
    if (sig.r < BigInt.one || sig.r >= n || sig.s < BigInt.one || sig.s >= n) {
      return false;
    }
    final t = (sig.r + sig.s) % n;
    if (t == BigInt.zero) {
      return false;
    }
    final point = (params.G * sig.s)! + (q * t);
    if (point == null || point.isInfinity) {
      return false;
    }
    final e = BigInt.parse(hex.encode(digest), radix: 16);
    final r = (e + point.x!.toBigInteger()!) % n;
    return r == sig.r;
  }

  static Future<bool> _verifyEd25519(
      PivPublicKey publicKey, Uint8List data, Uint8List signature) {
    final rawKey = publicKey.rawPublicKey;
    if (rawKey == null || rawKey.length != 32) {
      return Future.value(false);
    }
    return cryptography.Ed25519().verify(
      data,
      signature: cryptography.Signature(
        signature,
        publicKey: cryptography.SimplePublicKey(
          rawKey,
          type: cryptography.KeyPairType.ed25519,
        ),
      ),
    );
  }

  static RSAPublicKey _rsaPublicKey(Uint8List subjectPublicKeyInfo) {
    final spki = ASN1SubjectPublicKeyInfo.fromSequence(
        ASN1Sequence.fromBytes(subjectPublicKeyInfo));
    final publicKeyBytes =
        Uint8List.fromList(spki.subjectPublicKey.stringValues!);
    final publicKey = ASN1Sequence.fromBytes(publicKeyBytes);
    final modulus = publicKey.elements![0] as ASN1Integer;
    final exponent = publicKey.elements![1] as ASN1Integer;
    return RSAPublicKey(modulus.integer!, exponent.integer!);
  }

  static ECSignature _ecSignatureFromDer(Uint8List signature) {
    final sequence = ASN1Sequence.fromBytes(signature);
    final r = sequence.elements![0] as ASN1Integer;
    final s = sequence.elements![1] as ASN1Integer;
    return ECSignature(r.integer!, s.integer!);
  }

  static ECDomainParameters _ecDomainParameters(AlgorithmType algorithm) {
    switch (algorithm) {
      case AlgorithmType.eccp256:
        return ECDomainParameters('prime256v1');
      case AlgorithmType.eccp384:
        return ECDomainParameters('secp384r1');
      case AlgorithmType.eccp521:
        return ECDomainParameters('secp521r1');
      case AlgorithmType.secp256k1:
        return ECDomainParameters('secp256k1');
      case AlgorithmType.sm2:
        return PivSm2.domainParameters;
      default:
        throw ArgumentError('Unsupported EC algorithm: $algorithm');
    }
  }

  static Digest _ecDigest(AlgorithmType algorithm) {
    return switch (algorithm) {
      AlgorithmType.eccp384 => SHA384Digest(),
      AlgorithmType.eccp521 => SHA512Digest(),
      _ => SHA256Digest(),
    };
  }
}

class PivSm2 {
  static final ECDomainParameters domainParameters = _domainParameters();

  static Uint8List digest(Uint8List data, Uint8List point) {
    if (point.length != 65 || point.first != 0x04) {
      throw ArgumentError('Invalid SM2 public key');
    }
    final userId = Uint8List.fromList('1234567812345678'.codeUnits);
    final entl = userId.length * 8;
    final za = Sm3Digest.digest([
      entl >> 8,
      entl & 0xFF,
      ...userId,
      ..._a,
      ..._b,
      ..._gx,
      ..._gy,
      ...point.sublist(1, 33),
      ...point.sublist(33),
    ]);
    return Sm3Digest.digest([...za, ...data]);
  }

  static ECDomainParameters _domainParameters() {
    final curve = ecc_fp.ECCurve(
      BigInt.parse(
          'FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF',
          radix: 16),
      BigInt.parse(
          'FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC',
          radix: 16),
      BigInt.parse(
          '28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93',
          radix: 16),
    );
    final g = curve.createPoint(
      BigInt.parse(
          '32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7',
          radix: 16),
      BigInt.parse(
          'BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0',
          radix: 16),
    );
    return ECDomainParametersImpl(
      'sm2p256v1',
      curve,
      g,
      BigInt.parse(
          'FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFF7203DF6B21C6052B53BBF40939D54123',
          radix: 16),
      BigInt.one,
    );
  }

  static final Uint8List _a = Uint8List.fromList(hex.decode(
      'FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC'));
  static final Uint8List _b = Uint8List.fromList(hex.decode(
      '28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93'));
  static final Uint8List _gx = Uint8List.fromList(hex.decode(
      '32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7'));
  static final Uint8List _gy = Uint8List.fromList(hex.decode(
      'BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0'));
}
