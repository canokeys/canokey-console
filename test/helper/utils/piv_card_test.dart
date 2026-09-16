@Tags(['native'])
library;

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:convert/convert.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);
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
      expect(transport.commands, [
        '0020008008313233343536FFFF',
        '00CB3FFF055C035FFF0000',
        '00DB3FFF0C5C035FFF0053058003810103',
        '00CB3FFF055C035FC10900',
        '00CB3FFF055C035FFF0000',
      ]);
    });
  });

  test(
    'object writes preserve legacy Le and terminate on uncertain replies',
    () async {
      for (final response in ['019000', '6C10', '6982']) {
        final transport = _QueueApduTransport([response]);
        await _withPreparedClient(transport, (client) async {
          await expectLater(
            client.writeObject(0x5fff00, Uint8List(0)),
            throwsA(isA<ProtocolException>()),
          );
          expect(transport.commands, ['00DB3FFF075C035FFF00530000']);
          await expectLater(client.verifyPin('123456'), throwsStateError);
        }, firmware: '1.6.0');
      }
    },
  );

  test('chained object failure never resumes or replays', () async {
    final transport = _QueueApduTransport(['9000', '6F00']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.writeObject(0x5fc105, Uint8List(600)),
        throwsA(isA<ProtocolException>()),
      );
      expect(transport.commands, hasLength(2));
      expect(transport.commands.first, startsWith('10DB3FFF'));
      await expectLater(client.readObject(0x5fff00), throwsStateError);
    });
  });

  test(
    'cancelled object write drains I/O and invalidates preparation',
    () async {
      PivCardClient? active;
      final transport = _QueueApduTransport(
        ['9000'],
        beforeResponse: (command) async {
          if (command.startsWith('10DB')) active!.cancelPendingOperations();
        },
      );
      await _withPreparedClient(transport, (client) async {
        active = client;
        await expectLater(
          client.writeObject(0x5fc105, Uint8List(600)),
          throwsStateError,
        );
        expect(transport.commands, hasLength(1));
      });
    },
  );

  test('malformed object does not become absent or keep preparation', () async {
    final transport = _QueueApduTransport(['530080009000']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.readObject(0x5fff00),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.exchangeAttempted,
            'exchangeAttempted',
            isTrue,
          ),
        ),
      );
      await expectLater(client.verifyPin('123456'), throwsStateError);
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

  test('certificate requires an explicitly prepared lease', () async {
    final transport = _QueueApduTransport([]);
    final client = PivCardClient(transport: transport);
    await client.withSession(() async {
      await expectLater(client.readCertificate(5), throwsStateError);
    });
    expect(transport.commands, isEmpty);
  });

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
        expect(transport.commands, List.filled(5, '0020008000'));
      });
    },
  );

  test(
    'PUK change and PIN unblock share PIN encoding and report failures',
    () async {
      final transport = _QueueApduTransport(['63C2', '9000']);
      await _withPreparedClient(transport, (client) async {
        expect(await client.changePuk('12345678', '87654321'), isFalse);
        expect(client.lastStatusWord, '63C2');
        expect(await client.unblockPin('87654321', '123456'), isTrue);
        expect(client.lastStatusWord, '9000');
        expect(transport.commands, [
          '002400811031323334353637383837363534333231',
          '002C0080103837363534333231313233343536FFFF',
        ]);

        await expectLater(
          client.changePuk('123456789', '87654321'),
          throwsA(isA<ProtocolException>()),
        );
        await expectLater(
          client.unblockPin('87654321', '123456789'),
          throwsA(isA<ProtocolException>()),
        );
        expect(transport.commands, hasLength(2));
      });
    },
  );

  test(
    'credential failures keep retries but uncertain writes invalidate preparation',
    () async {
      final transport = _QueueApduTransport(['63C2', '9000', '019000']);
      await _withPreparedClient(transport, (client) async {
        expect(await client.verifyPin('123456'), isFalse);
        expect(client.lastStatusWord, '63C2');
        expect(await client.verifyPin('123456'), isTrue);
        await expectLater(
          client.changePin('123456', '654321'),
          throwsA(
            isA<ProtocolException>().having(
              (e) => e.details.kind,
              'kind',
              'InvalidResponse',
            ),
          ),
        );
        await expectLater(client.verifyPin('123456'), throwsStateError);
        expect(transport.commands, hasLength(3));
      });
    },
  );

  test(
    'SELECT and session release invalidate prepared credential factories',
    () async {
      final transport = _QueueApduTransport(['9000']);
      await _withPreparedClient(transport, (client) async {
        await client.select();
        await expectLater(client.verifyPin('123456'), throwsStateError);
        expect(transport.commands, ['00A4040005A00000030800']);
      });
      final client = PivCardClient(transport: _QueueApduTransport([]));
      await expectLater(client.verifyPin('123456'), throwsStateError);
    },
  );

  test(
    'unexpected status queries stay errors and cannot invent retry counts',
    () async {
      for (final response in ['6D00', '6A88', '6F00', '019000']) {
        await _withPreparedClient(_QueueApduTransport([response]), (
          client,
        ) async {
          await expectLater(
            client.readRemainingPinRetries(),
            throwsA(isA<ProtocolException>()),
          );
          await expectLater(client.verifyPin('123456'), throwsStateError);
        });
      }
    },
  );

  test(
    'management authentication uses upstream TDES and AES known-answer vectors',
    () async {
      for (final vector in [
        (
          AlgorithmType.tdes,
          '0123456789abcdef23456789abcdef01456789abcdef0123',
          '7C0A8108FEDCBA98765432109000',
          '0087039B0C7C0A82080737F6C53750D4A400',
        ),
        (
          AlgorithmType.aes192,
          '000102030405060708090a0b0c0d0e0f1011121314151617',
          '7C12811000112233445566778899AABBCCDDEEFF9000',
          '00870A9B147C128210DDA97CA4864CDFE06EAF70A0EC0D7191',
        ),
      ]) {
        final transport = _QueueApduTransport([
          '9000',
          vector.$3,
          '9000',
          '9000',
        ]);
        await _withPreparedClient(transport, (client) async {
          expect(await client.verifyPin('123456'), isTrue);
          expect(
            await client.authenticateManagementKey(vector.$2, vector.$1),
            isTrue,
          );
          expect(await client.readPinRetries(), '9000');
          expect(transport.commands, [
            vector.$1 == AlgorithmType.tdes
                ? '0020008008313233343536FFFF00'
                : '0020008008313233343536FFFF',
            vector.$1 == AlgorithmType.tdes
                ? '0087039B047C02810000'
                : '00870A9B047C028100',
            vector.$4,
            '0020008000',
          ]);
        }, firmware: vector.$1 == AlgorithmType.tdes ? '3.0.3' : '3.1.0');
      }
    },
  );

  test('management authentication owns the lease across both APDUs', () async {
    final started = Completer<void>();
    final finish = Completer<void>();
    final transport = _QueueApduTransport(
      [
        ..._probeResponses,
        '7C12811000112233445566778899AABBCCDDEEFF9000',
        '9000',
      ],
      beforeResponse: (command) async {
        if (command == '00870A9B047C028100') {
          started.complete();
          await finish.future;
        }
      },
    );
    final client = PivCardClient(transport: transport);
    await client.withSession(() async {
      await client.prepare();
      final auth = client.authenticateManagementKey(
        '000102030405060708090a0b0c0d0e0f1011121314151617',
        AlgorithmType.aes192,
      );
      await started.future;
      await expectLater(client.prepare(), throwsStateError);
      await expectLater(client.verifyPin('123456'), throwsStateError);
      finish.complete();
      expect(await auth, isTrue);
      expect(transport.commands, hasLength(9));
    });
  });

  test(
    'malformed management challenges are terminal with no authentication response',
    () async {
      for (final response in [
        '7C038101009000',
        '7C0A810800112233445566777C009000',
        '6C08',
      ]) {
        final transport = _QueueApduTransport([response]);
        await _withPreparedClient(transport, (client) async {
          await expectLater(
            client.authenticateManagementKey(
              '000102030405060708090a0b0c0d0e0f1011121314151617',
              AlgorithmType.aes192,
            ),
            throwsA(isA<ProtocolException>()),
          );
          expect(transport.commands, hasLength(1));
          await expectLater(client.verifyPin('123456'), throwsStateError);
        });
      }
    },
  );

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
      expect(certificate, hasLength(867));
      expect(transport.commands, [
        '00CB3FFF055C035FC10500',
        '00C00000FF',
        '00C00000FF',
        '00C0000072',
      ]);
    },
  );

  test(
    'reads short and one-byte long lengths and reordered metadata',
    () async {
      for (final response in [
        '530a7003300100710100fe009000',
        '530a7101007003300100fe009000',
        '530570033001009000',
      ]) {
        await _withPreparedClient(_QueueApduTransport([response]), (
          client,
        ) async {
          expect(await client.readCertificate(0x0a), [0x30, 0x01, 0x00]);
        });
      }
      final bytes = [0x30, 0x7e, ...List.filled(126, 0)];
      final response = hex.encode([
        0x53,
        0x81,
        0x88,
        0x70,
        0x81,
        0x80,
        ...bytes,
        0x71,
        0x01,
        0x00,
        0xfe,
        0x00,
        0x90,
        0x00,
      ]);
      await _withPreparedClient(_QueueApduTransport([response]), (
        client,
      ) async {
        expect(await client.readCertificate(0x0a), bytes);
      });
    },
  );

  test(
    'returns null for a missing certificate and rejects invalid objects',
    () async {
      for (final sw in ['6A82', '6A88']) {
        await _withPreparedClient(_QueueApduTransport([sw]), (missing) async {
          expect(await missing.readCertificate(0x05), isNull);
          expect(missing.lastStatusWord, sw);
        });
      }
      for (final response in [
        '70033001009000', // no outer object
        '53037101009000', // no certificate
        '530270009000', // empty certificate
        '5382019000', // truncated length
        '530a700330019000', // truncated value
        '530970033001007100fe009000', // empty certificate information
        '530a700330010070033001009000', // duplicate certificate
        '530870033001007101029000', // unsupported information flags
        '5305700330010053009000', // duplicate outer object
        '5307700330010001009000', // unknown certificate field
      ]) {
        await _withPreparedClient(_QueueApduTransport([response]), (
          client,
        ) async {
          await expectLater(
            client.readCertificate(0x05),
            throwsA(isA<ProtocolException>()),
          );
        });
      }
      await expectLater(
        _withPreparedClient(
          _QueueApduTransport(['530a7003300100710101fe009000']),
          (client) => client.readCertificate(0x05),
        ),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'InvalidResponse',
          ),
        ),
      );
    },
  );

  test(
    'reads gzip certificates and rejects trailing or corrupt gzip',
    () async {
      final der = File('test/fixtures/piv/certificate.der').readAsBytesSync();
      final compressed = gzip.encode(der);
      List<int> tlv(int tag, List<int> data) => [
        tag,
        if (data.length < 128)
          data.length
        else ...[
          0x82,
          data.length >> 8,
          data.length & 0xff,
        ],
        ...data,
      ];
      Future<List<int>?> read(List<int> payload) {
        final object = tlv(0x53, [...tlv(0x70, payload), 0x71, 1, 1, 0xfe, 0]);
        final responses = <String>[];
        for (var offset = 0; offset < object.length; offset += 256) {
          final end = (offset + 256).clamp(0, object.length);
          responses.add(
            hex.encode([
              ...object.sublist(offset, end),
              if (end == object.length) ...[0x90, 0] else ...[0x61, 0],
            ]),
          );
        }
        return _withPreparedClient(
          _QueueApduTransport(responses),
          (client) => client.readCertificate(0x05),
        );
      }

      expect(await read(compressed), der);
      await expectLater(
        read(gzip.encode(List.filled(1024 * 1024 + 1, 0))),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'LimitExceeded',
          ),
        ),
      );
      for (final invalid in [
        [...compressed, 0],
        [...compressed, ...compressed],
        compressed.sublist(0, compressed.length - 1),
        [...compressed]..[compressed.length - 8] ^= 1,
      ]) {
        await expectLater(read(invalid), throwsA(isA<ProtocolException>()));
      }
    },
  );

  test('certificate errors stay visible and clear stale status', () async {
    for (final status in ['6982', '6983', '6D00', '6F00']) {
      final transport = _QueueApduTransport([status]);
      await _withPreparedClient(transport, (client) async {
        await expectLater(
          client.readCertificate(0x05),
          throwsA(
            isA<ProtocolException>().having(
              (e) => e.details.statusWord,
              'status',
              int.parse(status, radix: 16),
            ),
          ),
        );
        expect(client.lastStatusWord, status);
        expect(transport.commands, ['00CB3FFF055C035FC10500']);
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
      expect(transport.commands, hasLength(3));
    });
  });

  test(
    'runs PIV metadata and PIN operations through the injected transport',
    () async {
      final transport = _QueueApduTransport([
        '0102039000',
        '63C3',
        '9000',
        '9000',
        '9000',
        '0101FF050101060203039000',
      ]);
      await _withPreparedClient(transport, (client) async {
        expect(await client.readVersion(), [1, 2, 3]);
        expect(await client.readSerial(), '01020304');
        expect(await client.readPinRetries(), '63C3');
        expect(await client.verifyPin('123456'), isTrue);
        expect(await client.changePin('123456', '654321'), isTrue);
        await client.logout();
        final metadata = await client.readMetadata(0x80);

        expect(metadata, isNotNull);
        expect(metadata!.retriesCount, 3);
        expect(metadata.remainingCount, 3);
        expect(transport.commands, [
          '00FD000000',
          '0020008000',
          '0020008008313233343536FFFF',
          '0024008010313233343536FFFF363534333231FFFF',
          '0020FF8000',
          '00F7008000',
        ]);
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
      for (final command in transport.commands) {
        expect(command, startsWith('0024008110'));
        expect(command.length, 42);
        expect(command.substring(10, 26), command.substring(26));
      }
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
    for (final response in ['9000', '63C1']) {
      final transport = _QueueApduTransport(List.filled(257, response));
      expect(
        await _withPreparedClient(transport, (client) => client.blockPuk()),
        isFalse,
      );
      expect(transport.commands, hasLength(257));
    }
  });

  test(
    'libcanokey version handles continuation without an extra SELECT',
    () async {
      final transport = _QueueApduTransport(['6C03', '066102', '00009000']);
      expect(await PivCardClient(transport: transport).readVersion(), [
        6,
        0,
        0,
      ]);
      expect(transport.commands, ['00FD000000', '00FD000003', '00C0000002']);
    },
  );

  test(
    'algorithm configuration propagates malformed replies and survives the gate',
    () async {
      for (final response in ['6F00', '019000']) {
        final transport = _QueueApduTransport([response]);
        await _withPreparedClient(transport, (client) async {
          await expectLater(
            client.readAlgorithmExtensions(),
            throwsA(isA<ProtocolException>()),
          );
          expect(transport.commands, ['00EE010000']);
        });
      }

      // The 3.0.x management-key gate (6982) falls back to defaults and keeps
      // the profile evidence: dependent reads continue without re-discovery.
      final transport = _QueueApduTransport(['6982', '9000']);
      await _withPreparedClient(transport, (client) async {
        expect(await client.readAlgorithmExtensions(), isNull);
        expect(await client.readPinRetries(), '9000');
        expect(transport.commands, ['00EE010000', '0020008000']);
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
        // One SELECT, then the authentication exchange and the gated read.
        expect(transport.commands, [
          '00A4040005A00000030800',
          '0087039B047C02810000',
          '0087039B0C7C0A82080737F6C53750D4A400',
          '00EE010000',
        ]);
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
    final unsupported = _QueueApduTransport(['6D00']);
    await _withPreparedClient(unsupported, (client) async {
      expect(await client.readAlgorithmExtensions(), isNull);
      expect(unsupported.commands, ['00EE010000']);
    });

    // Firmware without the read fails the capability check at construction:
    // zero I/O, same null fallback.
    final legacy = _QueueApduTransport([]);
    await _withPreparedClient(legacy, (client) async {
      expect(await client.readAlgorithmExtensions(), isNull);
      expect(legacy.commands, isEmpty);
    }, firmware: '2.0.0');

    expect(
      await _withPreparedClient(
        _QueueApduTransport(['6A88']),
        (client) => client.readMetadata(0x80),
      ),
      isNull,
    );
  });

  test('follows metadata GET RESPONSE and validates PIN length', () async {
    final transport = _QueueApduTransport(['0101FF6104', '050101060203039000']);
    await _withPreparedClient(transport, (client) async {
      final metadata = await client.readMetadata(0x80);

      expect(metadata, isNotNull);
      expect(transport.commands, ['00F7008000', '00C0000004']);
      await expectLater(
        client.verifyPin('123456789'),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  test(
    'metadata never falls back on security, unsupported or malformed responses',
    () async {
      for (final response in [
        '6982',
        '6D00',
        '6700',
        '0101FF0101FF9000',
        '0601039000',
      ]) {
        final transport = _QueueApduTransport([response]);
        await _withPreparedClient(transport, (client) async {
          await expectLater(
            client.readMetadata(0x80),
            throwsA(isA<ProtocolException>()),
          );
          expect(transport.commands, ['00F7008000']);
        });
      }
    },
  );

  test(
    'metadata profile expires at lease end and reads do not re-probe',
    () async {
      final transport = _QueueApduTransport([
        ..._probeResponses,
        '0101FF050101060203039000',
      ]);
      final client = PivCardClient(transport: transport);
      await client.withSession(() async {
        await expectLater(client.readMetadata(0x80), throwsStateError);
        expect(transport.commands, isEmpty);
        await client.prepare();
        expect(await client.readMetadata(0x80), isNotNull);
      });
      final count = transport.commands.length;
      await client.withSession(() async {
        await expectLater(client.readMetadata(0x80), throwsStateError);
      });
      expect(transport.commands, hasLength(count));
    },
  );

  test('metadata follows authentication without a SELECT or probe', () async {
    final transport = _QueueApduTransport(['9000', '0101FF050101060203039000']);
    await _withPreparedClient(transport, (client) async {
      expect(await client.verifyPin('123456'), isTrue);
      expect(await client.readMetadata(0x80), isNotNull);
      expect(transport.commands, ['0020008008313233343536FFFF', '00F7008000']);
    });
  });

  test(
    'legacy probe omits EE and metadata preserves legacy missing-slot status',
    () async {
      final responses = [..._probeResponses.take(6)];
      responses[1] =
          '322E302E309000'; // Actual firmware 2.0.0, not PIV version.
      final transport = _QueueApduTransport([...responses, '6900']);
      final client = PivCardClient(transport: transport);
      await client.withSession(() async {
        await client.prepare();
        expect(transport.commands, hasLength(6));
        expect(await client.readMetadata(0x9a), isNull);
        expect(client.lastStatusWord, '6900');
        expect(transport.commands.last, '00F7009A00');
        expect(transport.commands, isNot(contains('00EE010000')));
      });
    },
  );

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
    'competing preparation cannot close an in-flight metadata profile',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      final transport = _QueueApduTransport(
        [..._probeResponses, '010111020200000301019000'],
        beforeResponse: (command) async {
          if (command == '00F7009A00') {
            started.complete();
            await finish.future;
          }
        },
      );
      final client = PivCardClient(transport: transport);
      await client.withSession(() async {
        await client.prepare();
        final metadata = client.readMetadata(0x9a);
        await started.future;
        await expectLater(client.prepare(), throwsStateError);
        finish.complete();
        expect((await metadata)!.algorithm, AlgorithmType.eccp256);
        expect(transport.commands, hasLength(8));
      });
    },
  );

  test('failed re-probe cannot leave an old profile available', () async {
    final transport = _QueueApduTransport([..._probeResponses, '6F00']);
    final client = PivCardClient(transport: transport);
    await client.withSession(() async {
      await client.prepare();
      await expectLater(client.prepare(), throwsA(isA<ProtocolException>()));
      await expectLater(client.readMetadata(0x80), throwsStateError);
      expect(transport.commands, hasLength(8));
    });
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

  test('post-quantum seed import owns INS FE framing and policies', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      await client.importPqSeed(
        slot: 0x9a,
        kind: 0,
        seed: Uint8List.fromList(List.filled(32, 0x07)),
        pinPolicy: 2,
        touchPolicy: 3,
      );
      await client.importPqSeed(
        slot: 0x9d,
        kind: 1,
        seed: Uint8List.fromList(List.filled(64, 0x08)),
      );
      expect(client.lastStatusWord, '9000');
      expect(transport.commands, [
        '00FEE29A280920${'07' * 32}AA0102AB0103',
        '00FEE39D420A40${'08' * 64}',
      ]);
    });
  });

  test(
    'post-quantum seed import rejects invalid arguments before any exchange',
    () async {
      final transport = _QueueApduTransport(['9000']);
      await _withPreparedClient(transport, (client) async {
        for (final (slot, kind, length) in [
          (0x9a, 0, 31), // short ML-DSA-65 seed
          (0x9a, 1, 32), // ML-KEM-768 seed with the ML-DSA-65 length
          (0x9a, 2, 32), // unknown kind
          (0x96, 0, 32), // slot outside 9A/9C-9E/82-95
        ]) {
          await expectLater(
            client.importPqSeed(
              slot: slot,
              kind: kind,
              seed: Uint8List(length),
            ),
            throwsA(
              isA<ProtocolException>().having(
                (e) => e.exchangeAttempted,
                'exchangeAttempted',
                isFalse,
              ),
            ),
          );
        }
        expect(transport.commands, isEmpty);
        await client.importPqSeed(slot: 0x9a, kind: 0, seed: Uint8List(32));
        expect(transport.commands, ['00FEE29A220920${'00' * 32}']);
      });
    },
  );

  test(
    'post-quantum seed import failures retain the status and end preparation',
    () async {
      final transport = _QueueApduTransport(['6982']);
      await _withPreparedClient(transport, (client) async {
        await expectLater(
          client.importPqSeed(slot: 0x9a, kind: 0, seed: Uint8List(32)),
          throwsA(isA<ProtocolException>()),
        );
        expect(client.lastStatusWord, '6982');
        expect(transport.commands, ['00FEE29A220920${'00' * 32}']);
        await expectLater(
          client.importPqSeed(slot: 0x9a, kind: 0, seed: Uint8List(32)),
          throwsStateError,
        );
      });
    },
  );

  test(
    'post-quantum seed import requires evidenced PQ algorithm IDs',
    () async {
      final transport = _QueueApduTransport([]);
      await _withPreparedClient(transport, (client) async {
        await expectLater(
          client.importPqSeed(slot: 0x9a, kind: 0, seed: Uint8List(32)),
          throwsA(
            isA<ProtocolException>().having(
              (e) => e.exchangeAttempted,
              'exchangeAttempted',
              isFalse,
            ),
          ),
        );
        expect(transport.commands, isEmpty);
      }, firmware: '2.0.0');
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
    expect(transport.commands, [
      '00A4040005F00000000000',
      '0031000000',
      '0031010000',
      '0032000000',
      '00A4040005A00000030800',
      '00FD000000',
      if (!legacy) '00EE010000',
    ]);
    transport.commands.clear();
    return action(client);
  });
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(List<String> responses, {this.beforeResponse})
    : responses = List.of(responses);
  final Future<void> Function(String)? beforeResponse;

  final List<String> responses;
  final List<String> commands = [];
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    await beforeResponse?.call(capdu);
    return responses[_responseIndex++];
  }
}
