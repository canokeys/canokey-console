@Tags(['native'])
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test(
    'minimal discovery owns identity evidence without selecting PIV',
    () async {
      final transport = _Transport([]);
      await _prepared(transport, (client) async {
        expect(await client.readFirmwareVersion(), '3.1.0');
        expect(await client.readModel(), 'CanoKey');
        expect(await client.readSerial(), '01020304');
        expect(transport.commands, isEmpty);
      });
    },
  );

  test(
    'probe skips the serial read when the bootstrap observed it',
    () async {
      final transport = _Transport([
        '9000',
        '${hex.encode(utf8.encode('3.1.0'))}9000',
        '43616E6F4B65799000',
      ]);
      final client = AdminCardClient(transport: transport);
      await client.withSession(() async {
        client.lease.recordBootstrapSerial(Uint8List.fromList([1, 2, 3, 4]));
        await client.prepare();
        expect(await client.readSerial(), '01020304');
      });
    },
  );

  test(
    'bootstrap serial evidence requires exactly four bytes',
    () async {
      final transport = _Transport([]);
      final client = AdminCardClient(transport: transport);
      await client.withSession(() async {
        expect(
          () => client.lease.recordBootstrapSerial(Uint8List(3)),
          throwsArgumentError,
        );
      });
    },
  );

  test(
    'configuration, flash and applet usage use upstream validated results',
    () async {
      final usage = List.filled(48, 0)
        ..[0] = 7
        ..[1] = 0x81
        ..[5] = 42;
      final transport = _Transport([
        '01000001013F9000',
        '02089000',
        '${hex.encode(usage)}9000',
        'AABB9000',
      ]);
      await _prepared(transport, (client) async {
        expect(await client.readConfig(), [1, 0, 0, 1, 1, 63]);
        final flash = await client.readStorageUsage();
        expect((flash.usedKiB, flash.totalKiB), (2, 8));
        final entries = await client.readAppletStorageUsage();
        expect(entries, hasLength(8));
        expect((entries.first.appletId, entries.first.flags, entries.first.logicalBytes), (7, 0x81, 42));
        expect(entries.skip(1).every((entry) => entry.appletId == 0 && entry.flags == 0 && entry.logicalBytes == 0), isTrue);
        expect(await client.readChipId(), 'AABB');
      });
    },
  );

  test(
    'PIN changes keep their status word and report confirmed writes',
    () async {
      final transport = _Transport(['9000', '63C2', '9000', '9000', '9000']);
      await _prepared(transport, (client) async {
        await expectLater(
          client.changePin('654321', currentPin: '123456'),
          _kind('AuthenticationFailed'),
        );
        expect(client.lastStatusWord, '63C2');
        expect(client.lastProgress!.confirmedWrites, 0);
        await client.changePin('CanoKey密码', currentPin: '123456');
        expect(client.lastProgress!.confirmedWrites, 1);
        expect(client.lastProgress!.reprobeRequired, isFalse);
        final count = transport.commands.length;
        for (final pin in ['', '12345', List.filled(22, '密').join()]) {
          await expectLater(client.verifyPin(pin), _kind('InvalidPin'));
        }
        expect(transport.commands, hasLength(count));
      });
    },
  );

  test(
    'configuration patches report confirmed writes and required rediscovery',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '01000001013E9000',
        '9000',
        '9000',
      ]);
      await _prepared(transport, (client) async {
        await client.configure(
          pin: '123456',
          ledOn: false,
          featureMask: 1,
          featureValues: 1,
        );
        expect(client.lastProgress!.confirmedWrites, 2);
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );

  test(
    'partial configuration failure retains progress without rolling back',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '01000001013F9000',
        '9000',
        '6F00',
      ]);
      await _prepared(transport, (client) async {
        await expectLater(
          client.configure(pin: '123456', ledOn: false, ndefEnabled: false),
          _kind('UnexpectedStatusWord'),
        );
        expect(client.lastProgress!.confirmedWrites, 1);
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );

  test(
    'no-op patches report no writes and leave the profile usable',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '01000001013F9000',
        '9000',
        '01000001013F9000',
      ]);
      await _prepared(transport, (client) async {
        await client.configure(pin: '123456', ledOn: true);
        expect(client.lastProgress!.confirmedWrites, 0);
        expect(client.lastProgress!.reprobeRequired, isFalse);
        expect(await client.readConfig(), hasLength(6));
      });
    },
  );

  test(
    'modern SM2 writes round-trip signed identifiers and require rediscovery',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '00000009FFFFFFCA9000',
        '9000',
        '9000',
        '00000009FFFFFFCA9000',
        '9000',
      ]);
      await _prepared(transport, (client) async {
        await client.writeSm2Config(
          pin: '123456',
          enabled: false,
          curveId: -2147483648,
          algoId: 2147483647,
        );
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );

  test('reserved SM2 identifiers never reach a write', () async {
    final transport = _Transport(['9000', '9000', '00000009FFFFFFCA9000']);
    await _prepared(transport, (client) async {
      await expectLater(
        client.writeSm2Config(
          pin: '123456',
          enabled: true,
          curveId: 1,
          algoId: -54,
        ),
        throwsArgumentError,
      );
    });
  });

  test('optional commit only falls back on unsupported feature', () async {
    for (final response in ['6D00', '9000', '6162639000']) {
      await _prepared(_Transport([response]), (client) async {
        expect(
          await client.readCoreCommit(),
          response == '6162639000' ? 'abc' : null,
        );
      });
    }
    await _prepared(_Transport(['6982']), (client) async {
      await expectLater(
        client.readCoreCommit(),
        _kind('SecurityStatusNotSatisfied'),
      );
    });
  });

  test(
    'NDEF reset and factory reset report progress and distinct failures',
    () async {
      await _prepared(_Transport(['9000', '9000', '9000']), (client) async {
        await client.resetNdef(pin: '123456');
        expect(client.lastProgress!.confirmedWrites, 1);
      });
      final transport = _Transport(['6985']);
      await _prepared(transport, (client) async {
        await expectLater(
          client.factoryReset(),
          _kind('ConditionsNotSatisfied'),
        );
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );
}

List<String> _probe(String firmware) => [
  '9000',
  '${hex.encode(utf8.encode(firmware))}9000',
  '43616E6F4B65799000',
  '010203049000',
];
Matcher _kind(String kind) => throwsA(
  isA<ProtocolException>().having((e) => e.details.kind, 'kind', kind),
);
Future<T> _prepared<T>(
  _Transport transport,
  Future<T> Function(AdminCardClient) body, {
  String firmware = '3.1.0',
}) async {
  transport.responses.insertAll(0, _probe(firmware));
  final client = AdminCardClient(transport: transport);
  return client.withSession(() async {
    await client.prepare();
    transport.commands.clear();
    return body(client);
  });
}

class _Transport implements ApduTransport {
  _Transport(List<String> responses) : responses = List.of(responses);
  final List<String> responses;
  final List<String> commands = [];
  @override
  Future<String> transceive(String command) async {
    commands.add(command);
    return responses.removeAt(0);
  }
}
