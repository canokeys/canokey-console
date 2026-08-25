const _publicKeyAlgorithmNames = <String, String>{
  '1.2.840.10040.4.1': 'DSA',
  '1.2.840.10045.2.1': 'EC',
  '1.2.840.113549.1.1.1': 'RSA',
  '1.2.156.10197.1.301': 'SM2',
  '1.3.101.110': 'X25519',
  '1.3.101.111': 'X448',
  '1.3.101.112': 'Ed25519',
  '1.3.101.113': 'Ed448',
  '2.16.840.1.101.3.4.3.17': 'ML-DSA-44',
  '2.16.840.1.101.3.4.3.18': 'ML-DSA-65',
  '2.16.840.1.101.3.4.3.19': 'ML-DSA-87',
  '2.16.840.1.101.3.4.4.1': 'ML-KEM-512',
  '2.16.840.1.101.3.4.4.2': 'ML-KEM-768',
  '2.16.840.1.101.3.4.4.3': 'ML-KEM-1024',
};

const _signatureAlgorithmNames = <String, String>{
  '1.2.840.10040.4.3': 'DSA with SHA-1',
  '1.2.840.10045.4.1': 'ECDSA with SHA-1',
  '1.2.840.10045.4.3.1': 'ECDSA with SHA-224',
  '1.2.840.10045.4.3.2': 'ECDSA with SHA-256',
  '1.2.840.10045.4.3.3': 'ECDSA with SHA-384',
  '1.2.840.10045.4.3.4': 'ECDSA with SHA-512',
  '1.2.840.113549.1.1.5': 'RSA with SHA-1',
  '1.2.840.113549.1.1.10': 'RSASSA-PSS',
  '1.2.840.113549.1.1.11': 'RSA with SHA-256',
  '1.2.840.113549.1.1.12': 'RSA with SHA-384',
  '1.2.840.113549.1.1.13': 'RSA with SHA-512',
  '1.2.840.113549.1.1.14': 'RSA with SHA-224',
  '1.2.156.10197.1.501': 'SM2 with SM3',
  '1.3.101.112': 'Ed25519',
  '1.3.101.113': 'Ed448',
  '2.16.840.1.101.3.4.3.17': 'ML-DSA-44',
  '2.16.840.1.101.3.4.3.18': 'ML-DSA-65',
  '2.16.840.1.101.3.4.3.19': 'ML-DSA-87',
};

String x509PublicKeyAlgorithmName(String identifier) =>
    _publicKeyAlgorithmNames[identifier] ?? identifier;

String x509SignatureAlgorithmName(String identifier) =>
    _signatureAlgorithmNames[identifier] ?? identifier;
