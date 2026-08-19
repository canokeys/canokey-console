import 'package:canokey_console/helper/utils/piv_management_key.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PivManagementKeyProtocol', () {
    test('builds legacy 3DES authentication APDUs', () {
      expect(
        PivManagementKeyProtocol.authenticateRequest(AlgorithmType.tdes),
        '0087039B047C028100',
      );
      expect(
        PivManagementKeyProtocol.authenticateResponse(
          AlgorithmType.tdes,
          hex.decode('0011223344556677'),
        ),
        '0087039B0C7C0A82080011223344556677',
      );
    });

    test('builds AES-192 authentication APDUs', () {
      expect(
        PivManagementKeyProtocol.authenticateRequest(AlgorithmType.aes192),
        '00870A9B047C028100',
      );
      expect(
        PivManagementKeyProtocol.authenticateResponse(
          AlgorithmType.aes192,
          hex.decode('00112233445566778899AABBCCDDEEFF'),
        ),
        '00870A9B147C12821000112233445566778899AABBCCDDEEFF',
      );
    });

    test('parses 3DES and AES-192 challenges', () {
      expect(
        hex.encode(PivManagementKeyProtocol.parseChallenge(
          hex.decode('7C0A81080011223344556677'),
          AlgorithmType.tdes,
        )),
        '0011223344556677',
      );
      expect(
        hex.encode(PivManagementKeyProtocol.parseChallenge(
          hex.decode('7C12811000112233445566778899AABBCCDDEEFF'),
          AlgorithmType.aes192,
        )),
        '00112233445566778899aabbccddeeff',
      );
    });

    test('rejects a challenge with the wrong block length', () {
      expect(
        () => PivManagementKeyProtocol.parseChallenge(
          hex.decode('7C0A81080011223344556677'),
          AlgorithmType.aes192,
        ),
        throwsFormatException,
      );
    });

    test('rejects an invalid management key before calling Rust', () {
      expect(
        () => PivManagementKeyProtocol.encryptChallenge(
          algorithm: AlgorithmType.aes192,
          key: const [0x00],
          challenge: hex.decode('00112233445566778899AABBCCDDEEFF'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an invalid challenge before calling Rust', () {
      expect(
        () => PivManagementKeyProtocol.encryptChallenge(
          algorithm: AlgorithmType.tdes,
          key: List<int>.filled(24, 0),
          challenge: const [0x00],
        ),
        throwsArgumentError,
      );
    });

    test('builds SET MANAGEMENT KEY APDUs for legacy and new core', () {
      const key = '010203040506070801020304050607080102030405060708';
      expect(
        PivManagementKeyProtocol.setManagementKey(
          algorithm: AlgorithmType.tdes,
          key: key,
          touchPolicy: TouchPolicy.never,
        ),
        '00FFFFFF1B039B18$key',
      );
      expect(
        PivManagementKeyProtocol.setManagementKey(
          algorithm: AlgorithmType.aes192,
          key: key,
          touchPolicy: TouchPolicy.never,
        ),
        '00FFFFFF1B0A9B18$key',
      );
      expect(
        PivManagementKeyProtocol.setManagementKey(
          algorithm: AlgorithmType.aes192,
          key: key,
          touchPolicy: TouchPolicy.always,
        ),
        '00FFFFFE1B0A9B18$key',
      );
    });
  });
}
