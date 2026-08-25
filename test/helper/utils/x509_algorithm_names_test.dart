import 'package:canokey_console/helper/utils/x509_algorithm_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps PIV public key algorithm OIDs to display names', () {
    expect(x509PublicKeyAlgorithmName('1.2.840.113549.1.1.1'), 'RSA');
    expect(x509PublicKeyAlgorithmName('1.2.840.10045.2.1'), 'EC');
    expect(x509PublicKeyAlgorithmName('1.3.101.112'), 'Ed25519');
    expect(x509PublicKeyAlgorithmName('1.2.156.10197.1.301'), 'SM2');
    expect(
      x509PublicKeyAlgorithmName('2.16.840.1.101.3.4.3.18'),
      'ML-DSA-65',
    );
    expect(
      x509PublicKeyAlgorithmName('2.16.840.1.101.3.4.4.2'),
      'ML-KEM-768',
    );
  });

  test('maps PIV certificate signature OIDs to display names', () {
    expect(
      x509SignatureAlgorithmName('1.2.840.113549.1.1.11'),
      'RSA with SHA-256',
    );
    expect(
      x509SignatureAlgorithmName('1.2.840.10045.4.3.2'),
      'ECDSA with SHA-256',
    );
    expect(x509SignatureAlgorithmName('1.3.101.112'), 'Ed25519');
    expect(
      x509SignatureAlgorithmName('1.2.156.10197.1.501'),
      'SM2 with SM3',
    );
    expect(
      x509SignatureAlgorithmName('2.16.840.1.101.3.4.3.18'),
      'ML-DSA-65',
    );
  });

  test('keeps unknown algorithm identifiers unchanged', () {
    const oid = '1.2.3.4.5';
    expect(x509PublicKeyAlgorithmName(oid), oid);
    expect(x509SignatureAlgorithmName(oid), oid);
  });
}
