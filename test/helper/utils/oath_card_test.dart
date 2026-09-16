@Tags(['native'])
library;

import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

const _selectCommand = '00A4040007A0000005272101';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('builds OATH operations and follows calculate-all pagination', () async {
    // Every operation selects the applet before its target command.
    final transport = _QueueApduTransport([
      _modernSelection,
      _modernSelection, '9000', // put
      _modernSelection, '7605060000002A9000', // calculate
      _modernSelection, '9000', // delete
      _modernSelection, '710141760506000000019000', '6985', // calculateAll
    ]);
    await _withPreparedClient(transport, (client) async {
      final selection = await client.select();
      expect(selection.version, OathVersion.v2);
      expect(selection.requiresCode, isFalse);
      expect(hex.encode(selection.salt!), '3132333435363738');

      await client.put(
        name: 'A',
        secretHex: '0102',
        type: OathType.totp,
        algorithm: OathAlgorithm.sha1,
        digits: 6,
      );
      expect(client.lastStatusWord, '9000');

      final (digits, rawCode) = await client.calculate(
        name: 'A',
        type: OathType.totp,
        challengeHex: '0000000000000001',
      );
      expect((digits, rawCode), (6, 42));

      await client.delete('A');

      final entries = await client.calculateAll('0000000000000001');
      expect(entries.single.name, 'A');
      expect(entries.single.digits, 6);
      expect(entries.single.rawCode, 1);

      expect(transport.commands, [
        _selectCommand,
        _selectCommand, '0001000009710141730421060102',
        _selectCommand, '00A200010D71014174080000000000000001',
        _selectCommand, '0002000003710141',
        _selectCommand, '00A400010A74080000000000000001FF', '00A50000FF',
      ]);
    });
  });

  test('uses legacy commands and encodes a four-byte HOTP counter', () async {
    final transport = _QueueApduTransport([
      '9000', // legacy select returns no fields
      '9000', '9000', // put
      '9000', '7605060000002A9000', // calculate
    ]);
    await _withPreparedClient(transport, (client) async {
      expect((await client.select()).version, OathVersion.legacy);

      await client.put(
        name: 'A',
        secretHex: '0102',
        type: OathType.hotp,
        algorithm: OathAlgorithm.sha1,
        digits: 6,
        requireTouch: true,
        initialValue: 1,
      );
      await client.calculate(name: 'A', type: OathType.hotp);

      // Legacy firmware selects the 1.3 instruction set with explicit Le.
      expect(transport.commands, [
        '${_selectCommand}00',
        '${_selectCommand}00',
        '00010000127101417304110601027801027A040000000100',
        '${_selectCommand}00',
        '000400000371014100',
      ]);
    }, firmware: '1.3.0');
  });

  test('rejects invalid OATH challenge and counter sizes', () async {
    final transport = _QueueApduTransport([]);
    await _withPreparedClient(transport, (client) async {
      expect(
        () => client.calculate(
          name: 'A',
          type: OathType.totp,
          challengeHex: '00',
        ),
        throwsArgumentError,
      );
      expect(() => client.calculateAll('00'), throwsArgumentError);
      expect(
        () => client.put(
          name: 'A',
          secretHex: '0102',
          type: OathType.hotp,
          algorithm: OathAlgorithm.sha1,
          digits: 6,
          initialValue: 0x100000000,
        ),
        throwsRangeError,
      );
      expect(transport.commands, isEmpty);
    });
  });

  test('validates an access code within the operation', () async {
    final transport = _QueueApduTransport([
      _protectedSelection, // select
      _protectedSelection, // validate's own select
      '7514CAA1346E39058DD36ED76FB49053E14F66CE428B9000',
    ]);
    await _withPreparedClient(transport, (client) async {
      client.challengeGenerator =
          () => Uint8List.fromList('HHHHHHHH'.codeUnits);
      final selection = await client.select();
      expect(selection.version, OathVersion.v2);
      expect(selection.requiresCode, isTrue);

      // Key "KKKKKKKKKKKKKKKK", host challenge "HHHHHHHH", card challenge
      // "CCCCCCCC"; HMAC known-answer values from canokey-oath transcripts.
      await client.validate(Uint8List.fromList(List.filled(16, 0x4B)));
      expect(client.lastStatusWord, '9000');
      expect(transport.commands, [
        _selectCommand,
        _selectCommand,
        '00A3000020'
            '75140DE0BAE281BA21980E7692C934529F0F61111651'
            '74084848484848484848',
      ]);
    });
  });

  test('reports an incorrect access code with its status word', () async {
    final transport = _QueueApduTransport([_protectedSelection, '6A80']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.validate(Uint8List.fromList(List.filled(16, 0x4B))),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'AuthenticationFailed')
            .having((e) => e.details.phase, 'phase', 'Authentication')),
      );
      expect(client.lastStatusWord, '6A80');
    });
  });

  test('a protected applet rejects access-less operations before the target',
      () async {
    final transport = _QueueApduTransport([_protectedSelection]);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.delete('A'),
        throwsA(isA<ProtocolException>().having(
            (e) => e.details.kind, 'kind', 'SecurityStatusNotSatisfied')),
      );
      // The operation selected the applet, then failed before the delete.
      expect(transport.commands, [_selectCommand]);
    });
  });

  test('decodes code, HOTP and touch markers in calculate-all', () async {
    final transport = _QueueApduTransport([
      _modernSelection,
      '71014176050600000001'
          '710142770106'
          '7101437C0106'
          '9000',
      '6985',
    ]);
    await _withPreparedClient(transport, (client) async {
      final entries = await client.calculateAll('0000000000000001');
      expect(entries, hasLength(3));
      expect(entries[0].name, 'A');
      expect(entries[0].rawCode, 1);
      expect(entries[1].name, 'B');
      expect(entries[1].isHotp, isTrue);
      expect(entries[1].rawCode, isNull);
      expect(entries[2].name, 'C');
      expect(entries[2].requiresTouch, isTrue);
      expect(transport.commands, [
        _selectCommand,
        '00A400010A74080000000000000001FF',
        '00A50000FF',
      ]);
    });
  });

  test('surfaces a duplicate credential name as 6985', () async {
    final transport = _QueueApduTransport([_modernSelection, '6985']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.put(
          name: 'A',
          secretHex: '0102',
          type: OathType.totp,
          algorithm: OathAlgorithm.sha1,
          digits: 6,
        ),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.statusWord, 'statusWord', 0x6985)),
      );
      expect(client.lastStatusWord, '6985');
    });
  });

  test('set-default follows the modern two-slot dialect', () async {
    final transport = _QueueApduTransport([_modernSelection, '9000']);
    await _withPreparedClient(transport, (client) async {
      await client.setDefault(name: 'test', slot: 1, appendEnter: true);
      expect(client.lastStatusWord, '9000');
      expect(transport.commands, [
        _selectCommand,
        '0055020106710474657374',
      ]);
    });
  });

  test('set-default validates the access code within the operation', () async {
    final transport = _QueueApduTransport([
      _protectedSelection,
      '7514CAA1346E39058DD36ED76FB49053E14F66CE428B9000',
      '9000',
    ]);
    await _withPreparedClient(transport, (client) async {
      client.challengeGenerator =
          () => Uint8List.fromList('HHHHHHHH'.codeUnits);
      await client.setDefault(
        name: 'test',
        slot: 0,
        appendEnter: false,
        key: Uint8List.fromList(List.filled(16, 0x4B)),
      );
      expect(transport.commands, [
        _selectCommand,
        '00A3000020'
            '75140DE0BAE281BA21980E7692C934529F0F61111651'
            '74084848484848484848',
        '0055010006710474657374',
      ]);
    });
  });

  test('set-default on legacy firmware uses the zero-P1/P2 dialect', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      await client.setDefault(name: 'test', slot: 0, appendEnter: false);
      // Legacy firmware selects the 1.3 instruction set and the command
      // carries an explicit trailing Le.
      expect(transport.commands, [
        '${_selectCommand}00',
        '005500000671047465737400',
      ]);
    }, firmware: '1.3.0');
  });

  test('set-default on legacy firmware rejects long slots and enter before I/O',
      () async {
    final transport = _QueueApduTransport([]);
    await _withPreparedClient(transport, (client) async {
      for (final (slot, appendEnter) in [(1, false), (0, true)]) {
        await expectLater(
          client.setDefault(
            name: 'test',
            slot: slot,
            appendEnter: appendEnter,
          ),
          throwsA(isA<ProtocolException>()
              .having((e) => e.details.kind, 'kind', 'InvalidArgument')
              .having((e) => e.details.phase, 'phase', 'Construction')
              .having((e) => e.exchangeAttempted, 'exchangeAttempted', false)),
        );
      }
      expect(transport.commands, isEmpty);
      expect(client.lastStatusWord, isNull);
    }, firmware: '1.3.0');
  });

  test('set-default maps a missing name (6984) to NotFound', () async {
    final transport = _QueueApduTransport([_modernSelection, '6984']);
    await _withPreparedClient(transport, (client) async {
      await expectLater(
        client.setDefault(name: 'test', slot: 0, appendEnter: false),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'NotFound')
            .having((e) => e.details.statusWord, 'statusWord', 0x6984)),
      );
      expect(client.lastStatusWord, '6984');
    });
  });

  test('set-default rejects unknown slots', () async {
    final transport = _QueueApduTransport([]);
    await _withPreparedClient(transport, (client) async {
      expect(
        () => client.setDefault(name: 'test', slot: 2, appendEnter: false),
        throwsRangeError,
      );
      expect(transport.commands, isEmpty);
    });
  });
}

const _modernSelection = '7903060000710831323334353637389000';
const _protectedSelection = '790306000071083132333435363738'
    '74084343434343434343'
    '7B0101'
    '9000';

Future<T> _withPreparedClient<T>(
  _QueueApduTransport transport,
  Future<T> Function(OathCardClient) action, {
  String firmware = '3.1.0',
}) async {
  transport.responses.insertAll(0, [
    '9000',
    '${hex.encode(firmware.codeUnits)}9000',
    '43616E6F4B65799000',
    '010203049000',
  ]);
  final client = OathCardClient(transport: transport);
  return client.withSession(() async {
    await client.prepare();
    expect(transport.commands, [
      '00A4040005F00000000000',
      '0031000000',
      '0031010000',
      '0032000000',
    ]);
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
