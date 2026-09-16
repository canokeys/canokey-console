@Tags(['native'])
library;

import 'dart:convert';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('every operation SELECTs through libcanokey and follows GET RESPONSE',
      () async {
    final transport = _QueueApduTransport(['6102', '9000', '6A82']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.verifyAdminPin('12345678'),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'NotFound',
          ),
        ),
      );
      // The upstream engine owns continuation and Le correction.
      expect(transport.commands, [
        '00A4040006D27600012401',
        '00C0000002',
        '00200083083132333435363738',
      ]);
    });
  });

  test('operations require an explicitly prepared lease', () async {
    final transport = _QueueApduTransport([]);
    final client = OpenPgpCardClient(transport: transport);
    await client.withSession(() async {
      await expectLater(client.readCardInfo(), throwsStateError);
      await expectLater(
        client.changeUserPin('123456', '654321'),
        throwsStateError,
      );
    });
    expect(transport.commands, isEmpty);
  });

  test('reads card info with optional legacy data objects missing', () async {
    const aid = 'D2760001240103040000010203040000';
    const application = '4F10${aid}C40700000000030303';
    final transport = _QueueApduTransport([
      '9000',
      '${application}9000',
      '9000',
      '6A88',
      '9000',
      '6A88',
      '9000',
      '6A88',
    ]);

    final info = await _withPreparedClient(
      transport,
      (client) => client.readCardInfo(),
    );

    expect(info.version, '3.4');
    expect(info.serialNumber, '01020304');
    expect(info.pinState.userRetries, 3);
    expect(info.pinState.adminRetries, 3);
    expect(info.keySlots.keys, containsAll(OpenPgpKeyType.values));
    expect(info.keySlots.values.every((slot) => !slot.hasKey), isTrue);
    expect(info.touchCacheTime, isNull);
    expect(transport.commands, [
      '00A4040006D27600012401',
      '00CA006E00',
      '00A4040006D27600012401',
      '00CA006500',
      '00A4040006D27600012401',
      '00CA5F5000',
      '00A4040006D27600012401',
      '00CA010200',
    ]);
  });

  test('parses current card data, key metadata, and touch policies', () async {
    final fingerprints = [
      ...List<int>.generate(20, (index) => index + 1),
      ...List<int>.filled(20, 0),
      ...List<int>.filled(20, 0xAA),
    ];
    final application = _tlv(0x6E, [
      ..._tlv(0x4F, hex.decode('D2760001240103040006010203040000')),
      ..._tlv(0x73, [
        ..._tlv(0xC4, [0, 0, 0, 0, 3, 2, 1]),
        ..._tlv(0xC5, fingerprints),
        ..._tlv(0xCD, [0, 0, 0, 1, 0, 0, 0, 0, 0x65, 0, 0, 0]),
        ..._tlv(0xD6, [OpenPgpTouchPolicy.permanent.value, 0x20]),
        ..._tlv(0xD7, [OpenPgpTouchPolicy.cached.value, 0x20]),
        ..._tlv(0xD8, [OpenPgpTouchPolicy.cachedPermanent.value, 0x20]),
      ]),
    ]);
    final holder = _tlv(0x5B, utf8.encode('Alice Example'));
    final transport = _QueueApduTransport([
      '9000',
      '${hex.encode(application)}9000',
      '9000',
      '${hex.encode(holder)}9000',
      '9000',
      '${hex.encode(utf8.encode('https://example.test/key'))}9000',
      '9000',
      '0F9000',
    ]);

    final info = await _withPreparedClient(
      transport,
      (client) => client.readCardInfo(),
    );

    expect(info.manufacturer, 'Yubico');
    expect(info.cardHolder, 'Alice Example');
    expect(info.publicKeyUrl, 'https://example.test/key');
    expect(info.touchCacheTime, 15);
    expect(info.pinState.signaturePinForced, isTrue);
    expect(
      info.keySlots[OpenPgpKeyType.signature]!.fingerprint,
      '0102030405060708090A0B0C0D0E0F1011121314',
    );
    expect(
      info.keySlots[OpenPgpKeyType.signature]!.generatedAt,
      DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
    );
    expect(info.keySlots[OpenPgpKeyType.signature]!.touchFixed, isTrue);
    expect(info.keySlots[OpenPgpKeyType.encryption]!.fingerprint, isNull);
    expect(info.keySlots[OpenPgpKeyType.encryption]!.touchFixed, isFalse);
    expect(info.keySlots[OpenPgpKeyType.authentication]!.hasKey, isTrue);
    expect(info.keySlots[OpenPgpKeyType.authentication]!.touchFixed, isTrue);
  });

  test('legacy firmware gates the touch cache read before any exchange',
      () async {
    const aid = 'D2760001240103040000010203040000';
    const application = '4F10${aid}C40700000000030303';
    final transport = _QueueApduTransport([
      '9000',
      '${application}9000',
      '9000',
      '6A88',
      '9000',
      '6A88',
    ]);

    final info = await _withPreparedClient(
      transport,
      (client) => client.readCardInfo(),
      firmware: '1.3.0',
    );

    expect(info.touchCacheTime, isNull);
    // Legacy explicit Le applies to SELECT; the gated 0102 read performs no I/O.
    expect(transport.commands, [
      '00A4040006D2760001240100',
      '00CA006E00',
      '00A4040006D2760001240100',
      '00CA006500',
      '00A4040006D2760001240100',
      '00CA5F5000',
    ]);
  });

  test('changes the user PIN through libcanokey', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      expect(await client.changeUserPin('123456', '654321'), isTrue);
      expect(client.lastStatusWord, '9000');
      expect(transport.commands, [
        '00A4040006D27600012401',
        '002400810C313233343536363534333231',
      ]);
    });
  });

  test('changes the admin PIN through libcanokey', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      expect(await client.changeAdminPin('12345678', '87654321'), isTrue);
      expect(transport.commands, [
        '00A4040006D27600012401',
        '002400831031323334353637383837363534333231',
      ]);
    });
  });

  test('credential rejections keep the status word and retries', () async {
    final transport = _QueueApduTransport([
      '9000', '63C2', '9000', '6983', '9000', '6982', '9000', '9000',
    ]);
    await _withPreparedClient(transport, (client) async {
      expect(await client.changeUserPin('123456', '654321'), isFalse);
      expect(client.lastStatusWord, '63C2');
      expect(await client.changeAdminPin('12345678', '87654321'), isFalse);
      expect(client.lastStatusWord, '6983');
      expect(await client.verifyAdminPin('12345678'), isFalse);
      expect(client.lastStatusWord, '6982');
      expect(await client.verifyAdminPin('12345678'), isTrue);
      expect(transport.commands, [
        '00A4040006D27600012401',
        '002400810C313233343536363534333231',
        '00A4040006D27600012401',
        '002400831031323334353637383837363534333231',
        '00A4040006D27600012401',
        '00200083083132333435363738',
        '00A4040006D27600012401',
        '00200083083132333435363738',
      ]);
    });
  });

  test('invalid credential lengths fail before any exchange', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.changeUserPin('12345', '654321'),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'InvalidPin',
          ),
        ),
      );
      expect(transport.commands, isEmpty);
      expect(await client.changeUserPin('123456', '654321'), isTrue);
    });
  });

  test('builds OpenPGP administration operations', () async {
    final transport = _QueueApduTransport(List.filled(23, '9000'));
    await _withPreparedClient(transport, (client) async {
      expect(await client.setResetCode('12345678', '12345678'), isTrue);
      expect(await client.setResetCode('12345678', ''), isTrue);
      expect(await client.setPinRetries('12345678', 3, 3, 3), isTrue);
      expect(await client.setSignaturePinPolicy('12345678', true), isTrue);
      expect(
        await client.unblockUserPinWithAdmin('12345678', '123456'),
        isTrue,
      );
      expect(
        await client.unblockUserPinWithResetCode('12345678', '123456'),
        isTrue,
      );
      expect(
        await client.setTouchPolicy(
          OpenPgpKeyType.signature,
          OpenPgpTouchPolicy.on,
          '12345678',
        ),
        isTrue,
      );
      expect(await client.setTouchCacheTime('12345678', 15), isTrue);
    });

    final commands = transport.commands;
    expect(commands, contains('00DA00D3083132333435363738'));
    // Clearing the reset code is a dataless PUT DATA.
    expect(commands, contains('00DA00D3'));
    expect(commands, contains('00F2000003030303'));
    expect(commands, contains('00DA00C40100'));
    expect(commands, contains('002C028106313233343536'));
    expect(
      commands,
      contains('002C00810E3132333435363738313233343536'),
    );
    expect(commands, contains('00DA00D6020120'));
    expect(commands, contains('00DA0102010F'));
    // Every PW3-protected operation explicitly verifies after its own SELECT;
    // only the reset-code unblock skips verification.
    final verifyCount = commands
        .where((command) => command == '00200083083132333435363738')
        .length;
    expect(verifyCount, 7);
  });

  test(
    'all privileged operations stop on failed authentication and preserve status',
    () async {
      final operations = <Future<bool> Function(OpenPgpCardClient)>[
        (card) => card.setResetCode('12345678', '87654321'),
        (card) => card.setPinRetries('12345678', 3, 3, 3),
        (card) => card.setSignaturePinPolicy('12345678', true),
        (card) => card.unblockUserPinWithAdmin('12345678', '123456'),
        (card) => card.setTouchPolicy(
          OpenPgpKeyType.signature,
          OpenPgpTouchPolicy.on,
          '12345678',
        ),
        (card) => card.setTouchCacheTime('12345678', 15),
      ];
      for (final operation in operations) {
        for (final failure in ['6982', '63C2', '6983']) {
          final transport = _QueueApduTransport(['9000', failure]);
          await _withPreparedClient(transport, (client) async {
            expect(await operation(client), isFalse);
            expect(transport.commands, [
              '00A4040006D27600012401',
              '00200083083132333435363738',
            ]);
            expect(client.lastStatusWord, failure);
          });
        }
        // Unexpected target-stage statuses are protocol failures, not a
        // credential result; the status word is still preserved.
        final transport = _QueueApduTransport(['9000', '9000', '6581']);
        await _withPreparedClient(transport, (client) async {
          await expectLater(
            operation(client),
            throwsA(
              isA<ProtocolException>().having(
                (e) => e.details.statusWord,
                'statusWord',
                0x6581,
              ),
            ),
          );
          expect(client.lastStatusWord, '6581');
          expect(transport.commands, hasLength(3));
        });
      }
    },
  );

  test('administrative inputs are validated before any exchange', () async {
    final transport = _QueueApduTransport([]);
    await _withPreparedClient(transport, (client) async {
      // Reset codes must satisfy the 8..64 administrative length.
      await expectLater(
        client.setResetCode('12345678', List.filled(65, 'A').join()),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'InvalidPin',
          ),
        ),
      );
      // Retry limits are exactly three values in 1..15.
      await expectLater(
        client.setPinRetries('12345678', 0, 3, 3),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'InvalidArgument',
          ),
        ),
      );
      // A short reset code fails construction without I/O.
      await expectLater(
        client.unblockUserPinWithResetCode('123456', '654321'),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.details.kind,
            'kind',
            'InvalidPin',
          ),
        ),
      );
    });
    expect(transport.commands, isEmpty);
  });

  test('legacy firmware gates UIF and retry-limit writes before any exchange',
      () async {
    for (final firmware in ['1.3.0', '1.6.0']) {
      final transport = _QueueApduTransport([]);
      await _withPreparedClient(transport, firmware: firmware, (client) async {
        if (firmware == '1.3.0') {
          await expectLater(
            client.setTouchPolicy(
              OpenPgpKeyType.signature,
              OpenPgpTouchPolicy.on,
              '12345678',
            ),
            throwsA(
              isA<ProtocolException>().having(
                (e) => e.details.kind,
                'kind',
                'UnsupportedFeature',
              ),
            ),
          );
          await expectLater(
            client.setTouchCacheTime('12345678', 15),
            throwsA(
              isA<ProtocolException>().having(
                (e) => e.details.kind,
                'kind',
                'UnsupportedFeature',
              ),
            ),
          );
        } else {
          // Retry-limit configuration exists from firmware 3.1.0.
          await expectLater(
            client.setPinRetries('12345678', 3, 3, 3),
            throwsA(
              isA<ProtocolException>().having(
                (e) => e.details.kind,
                'kind',
                'UnsupportedFeature',
              ),
            ),
          );
        }
      });
      expect(transport.commands, isEmpty);
    }
  });

  test('reset-code unblock maps credential failures without a verify', () async {
    final transport = _QueueApduTransport([
      '9000', '63C2', '9000', '6983', '9000', '9000',
    ]);
    await _withPreparedClient(transport, (client) async {
      expect(
        await client.unblockUserPinWithResetCode('24682468', '654321'),
        isFalse,
      );
      expect(client.lastStatusWord, '63C2');
      expect(
        await client.unblockUserPinWithResetCode('24682468', '654321'),
        isFalse,
      );
      expect(client.lastStatusWord, '6983');
      expect(
        await client.unblockUserPinWithResetCode('24682468', '654321'),
        isTrue,
      );
      expect(transport.commands, [
        '00A4040006D27600012401',
        '002C00810E3234363832343638363534333231',
        '00A4040006D27600012401',
        '002C00810E3234363832343638363534333231',
        '00A4040006D27600012401',
        '002C00810E3234363832343638363534333231',
      ]);
    });
  });
}

List<int> _tlv(int tag, List<int> value) {
  final tagBytes = tag <= 0xFF ? [tag] : [tag >> 8, tag & 0xFF];
  return [...tagBytes, value.length, ...value];
}

const _probeCommands = [
  '00A4040005F00000000000',
  '0031000000',
  '0031010000',
  '0032000000',
];

Future<T> _withPreparedClient<T>(
  _QueueApduTransport transport,
  Future<T> Function(OpenPgpCardClient) action, {
  String firmware = '3.1.0',
}) async {
  transport.responses.insertAll(0, [
    '9000',
    '${hex.encode(firmware.codeUnits)}9000',
    '43616E6F4B65799000',
    '010203049000',
  ]);
  final client = OpenPgpCardClient(transport: transport);
  return client.withSession(() async {
    await client.prepare();
    expect(transport.commands, _probeCommands);
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
    if (_responseIndex >= responses.length) {
      throw StateError('No queued APDU response for $capdu');
    }
    return responses[_responseIndex++];
  }
}
