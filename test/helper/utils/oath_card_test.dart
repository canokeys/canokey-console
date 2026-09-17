@Tags(['native'])
library;

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('runs OATH operations and decodes their results', () async {
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
    });
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
    });
  });

  test('set-default reports success through libcanokey', () async {
    final transport = _QueueApduTransport([_modernSelection, '9000']);
    await _withPreparedClient(transport, (client) async {
      await client.setDefault(name: 'test', slot: 1, appendEnter: true);
      expect(client.lastStatusWord, '9000');
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
