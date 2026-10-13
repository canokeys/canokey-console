@Tags(['native'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/src/rust/api/piv_crypto.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:convert/convert.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);
  test('opaque private key supports retries and explicit cleanup', () async {
    final key = parsePivImportFile(
      bytes: Uint8List.fromList(
        hex.decode(
          '3041020100301306072a8648ce3d020106082a8648ce3d030107042730250201010420'
          '${List.filled(32, '03').join()}',
        ),
      ),
    ).privateKey!;
    final transport = _QueueApduTransport(['9000', '9000']);
    try {
      expect(key.algorithm, 0x11);
      expect(key.subjectPublicKeyInfo, isNotEmpty);
      await _withPreparedClient(transport, (client) async {
        for (var attempt = 0; attempt < 2; attempt++) {
          await client.importPrivateKey(
            slot: 0x9a,
            algorithm: 0x11,
            key: key,
            pinPolicy: 2,
            touchPolicy: 1,
          );
        }
        expect(transport.commands, hasLength(2));
        key.close();
        key.close();
        await expectLater(
          client.importPrivateKey(slot: 0x9a, algorithm: 0x11, key: key),
          throwsA(isA<ProtocolException>()),
        );
        expect(transport.commands, hasLength(2));
      });
    } finally {
      key.close();
      key.dispose();
    }
  });

  test('object reads and writes retain the authenticated selection', () async {
    final transport = _QueueApduTransport([
      '9000',
      '530580038101029000',
      '9000',
      '6A88',
      '53009000',
    ]);
    await _withPreparedClient(transport, (client) async {
      expect(await client.verifyPin('123456'), isTrue);
      expect(await client.readObject(0x5fff00), [0x80, 3, 0x81, 1, 2]);
      await client.writeObject(
        0x5fff00,
        Uint8List.fromList([0x80, 3, 0x81, 1, 3]),
      );
      expect(await client.readObject(0x5fc109), isNull);
      expect(await client.readObject(0x5fff00), isEmpty);
    });
  });

  test(
    'factory rejection has no exchange evidence and preserves preparation',
    () async {
      final transport = _QueueApduTransport(['9000']);
      await _withPreparedClient(transport, (client) async {
        await expectLater(
          client.verifyPin('1'),
          throwsA(
            isA<ProtocolException>().having(
              (e) => e.exchangeAttempted,
              'exchangeAttempted',
              isFalse,
            ),
          ),
        );
        expect(transport.commands, isEmpty);
        expect(await client.verifyPin('123456'), isTrue);
      });
    },
  );

  test(
    'empty VERIFY reads remaining attempts without guessing on success',
    () async {
      final transport = _QueueApduTransport([
        '63C3',
        '63c1',
        '63C0',
        '6983',
        '9000',
      ]);
      await _withPreparedClient(transport, (client) async {
        for (final expected in [3, 1, 0, 0, null]) {
          expect(await client.readRemainingPinRetries(), expected);
        }
      });
    },
  );

  test(
    'PUK change and PIN unblock report failures with their status word',
    () async {
      final transport = _QueueApduTransport(['63C2', '9000']);
      await _withPreparedClient(transport, (client) async {
        expect(await client.changePuk('12345678', '87654321'), isFalse);
        expect(client.lastStatusWord, '63C2');
        expect(await client.unblockPin('87654321', '123456'), isTrue);
        expect(client.lastStatusWord, '9000');
      });
    },
  );

  test('management authentication succeeds for TDES and AES keys', () async {
    for (final vector in [
      (
        AlgorithmType.tdes,
        '0123456789abcdef23456789abcdef01456789abcdef0123',
        '7C0A8108FEDCBA98765432109000',
      ),
      (
        AlgorithmType.aes192,
        '000102030405060708090a0b0c0d0e0f1011121314151617',
        '7C12811000112233445566778899AABBCCDDEEFF9000',
      ),
    ]) {
      final transport = _QueueApduTransport([vector.$3, '9000']);
      await _withPreparedClient(transport, (client) async {
        expect(
          await client.authenticateManagementKey(vector.$2, vector.$1),
          isTrue,
        );
      }, firmware: vector.$1 == AlgorithmType.tdes ? '3.0.3' : '3.1.0');
    }
  });

  test(
    'reads the reported four-part certificate without PIV metadata',
    () async {
      final responses = File(
        'test/fixtures/piv/certificate_response.txt',
      ).readAsLinesSync();
      final transport = _QueueApduTransport(responses);
      final certificate = await _withPreparedClient(
        transport,
        (client) => client.readCertificate(0x05),
      );
      expect(
        certificate,
        File('test/fixtures/piv/certificate.der').readAsBytesSync(),
      );
    },
  );

  test('returns null for a missing certificate', () async {
    for (final sw in ['6A82', '6A88']) {
      await _withPreparedClient(_QueueApduTransport([sw]), (missing) async {
        expect(await missing.readCertificate(0x05), isNull);
        expect(missing.lastStatusWord, sw);
      });
    }
  });

  test('certificate errors stay visible and clear stale status', () async {
    for (final status in ['6982', '6983', '6D00', '6F00']) {
      final transport = _QueueApduTransport([status]);
      await _withPreparedClient(transport, (client) async {
        await expectLater(
          client.readCertificate(0x05),
          throwsA(isA<ProtocolException>()),
        );
        expect(client.lastStatusWord, status);
      });
    }
    final transport = _QueueApduTransport([
      '6A88',
      'not hex',
      '530570033001009000',
    ]);
    await _withPreparedClient(transport, (client) async {
      expect(await client.readCertificate(0x05), isNull);
      await expectLater(client.readCertificate(0x05), throwsFormatException);
      expect(client.lastStatusWord, isNull);
      expect(await client.readCertificate(0x05), [0x30, 1, 0]);
      expect(client.lastStatusWord, '9000');
      for (final id in [-1, 256]) {
        await expectLater(client.readCertificate(id), throwsRangeError);
      }
    });
  });

  test(
    'runs PIV metadata and PIN operations through the injected transport',
    () async {
      final transport = _QueueApduTransport([
        '63C3',
        '9000',
        '9000',
        '0101FF050101060203039000',
      ]);
      await _withPreparedClient(transport, (client) async {
        expect(await client.readSerial(), '01020304');
        expect(await client.readPinRetries(), '63C3');
        expect(await client.verifyPin('123456'), isTrue);
        expect(await client.changePin('123456', '654321'), isTrue);
        final metadata = await client.readMetadata(0x80);

        expect(metadata, isNotNull);
        expect(metadata!.retriesCount, 3);
        expect(metadata.remainingCount, 3);
      });
    },
  );

  test(
    'blocks PUK through CHANGE REFERENCE DATA until confirmed blocked',
    () async {
      final transport = _QueueApduTransport(['63C2', '63C1', '63C0', '6983']);
      expect(
        await _withPreparedClient(transport, (client) => client.blockPuk()),
        isTrue,
      );
      expect(transport.commands, hasLength(4));
    },
  );

  test(
    'accepts an already blocked PUK and retries an accidental match',
    () async {
      for (final responses in [
        ['6983'],
        ['9000', '63C0', '6983'],
      ]) {
        final transport = _QueueApduTransport(responses);
        expect(
          await _withPreparedClient(transport, (client) => client.blockPuk()),
          isTrue,
        );
        expect(transport.commands, hasLength(responses.length));
      }
    },
  );

  test('PUK blocking stops on unexpected failures without retry', () async {
    for (final response in ['6982', '6A80', '6F00', '019000']) {
      final transport = _QueueApduTransport([response]);
      await expectLater(
        _withPreparedClient(transport, (client) => client.blockPuk()),
        throwsA(isA<ProtocolException>()),
      );
      expect(transport.commands, hasLength(1));
    }
    final transport = _QueueApduTransport(List.filled(257, '63C1'));
    expect(
      await _withPreparedClient(transport, (client) => client.blockPuk()),
      isFalse,
    );
    expect(transport.commands, hasLength(257));
  });

  test(
    'the 3.0.x management-key gate falls back to defaults and keeps the profile',
    () async {
      // The 6982 gate answer leaves card state untouched; dependent reads
      // continue on the same prepared profile.
      final transport = _QueueApduTransport(['6982', '9000']);
      await _withPreparedClient(transport, (client) async {
        expect(await client.readAlgorithmExtensions(), isNull);
        expect(await client.readPinRetries(), '9000');
      });
    },
  );

  test(
    'algorithm configuration authenticates the management key when supplied',
    () async {
      // 3.0.x firmware gates the read behind management-key authentication;
      // upstream SELECTs, authenticates and reads within one operation.
      final transport = _QueueApduTransport([
        '9000', // SELECT PIV
        '7C0A8108FEDCBA98765432109000', // management challenge
        '9000', // management authentication response
        '01E00516E1531554E2E39000', // extension configuration
      ]);
      await _withPreparedClient(transport, (client) async {
        final config = await client.readAlgorithmExtensions(
          managementKey: '0123456789abcdef23456789abcdef01456789abcdef0123',
        );
        expect(config, isNotNull);
        expect(config!.enabled, isTrue);
      }, firmware: '3.0.3');
    },
  );

  test('reads optional algorithm extensions and missing metadata', () async {
    await _withPreparedClient(
      _QueueApduTransport(['01E00516E1531554E2E39000']),
      (client) async {
        final config = await client.readAlgorithmExtensions();
        expect(config, isNotNull);
        expect(config!.enabled, isTrue);
      },
    );

    // A card-side unsupported instruction keeps the null fallback.
    await _withPreparedClient(_QueueApduTransport(['6D00']), (client) async {
      expect(await client.readAlgorithmExtensions(), isNull);
    });

    // Firmware without the read fails the capability check at construction:
    // same null fallback, without any I/O.
    await _withPreparedClient(_QueueApduTransport([]), (client) async {
      expect(await client.readAlgorithmExtensions(), isNull);
    }, firmware: '2.0.0');

    expect(
      await _withPreparedClient(
        _QueueApduTransport(['6A88']),
        (client) => client.readMetadata(0x80),
      ),
      isNull,
    );
  });

  test('incomplete metadata cannot invent UI retry or policy values', () async {
    for (final response in ['0101FF9000', '0101FF050102060203039000']) {
      await _withPreparedClient(_QueueApduTransport([response]), (
        client,
      ) async {
        await expectLater(client.readMetadata(0x80), throwsFormatException);
      });
    }
  });

  test(
    'metadata algorithms resolve through this device profile',
    () async {
      final responses = [..._probeResponses.take(6)];
      responses[1] = '322E302E309000';
      final transport = _QueueApduTransport([
        ...responses,
        '010122020200000301019000',
      ]);
      final client = PivCardClient(transport: transport);
      await client.withSession(() async {
        await client.prepare();
        final metadata = await client.readMetadata(0x9a);
        expect(metadata, isNotNull);
        expect(metadata!.algorithm, AlgorithmType.ed25519);
      });
    },
  );
}

const _probeResponses = [
  '9000',
  '332E312E309000',
  '43616E6F4B65799000',
  '010203049000',
  '9000',
  '0600009000',
  '01E00516E1531554E2E39000',
];

Future<T> _withPreparedClient<T>(
  _QueueApduTransport transport,
  Future<T> Function(PivCardClient) action, {
  String firmware = '3.1.0',
}) async {
  final probe = [..._probeResponses];
  final legacy = firmware.startsWith('1.') || firmware.startsWith('2.');
  if (legacy) probe.removeLast();
  probe[1] = '${hex.encode(firmware.codeUnits)}9000';
  transport.responses.insertAll(0, probe);
  final client = PivCardClient(transport: transport);
  return client.withSession(() async {
    await client.prepare();
    transport.commands.clear();
    return action(client);
  });
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(List<String> responses) : responses = List.of(responses);

  final List<String> responses;
  final List<String> commands = [];
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses[_responseIndex++];
  }
}
