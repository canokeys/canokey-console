@Tags(['native'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
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
        // No serial read: the bootstrap observation is the probe's evidence.
        expect(transport.commands, ['${_select}00', '0031000000', '0031010000']);
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
        expect(await client.readAppletStorageUsage(), usage);
        expect(await client.readChipId(), 'AABB');
        // The probe left Admin selected, so each read skips its own SELECT.
        expect(transport.commands, [
          '0042000000',
          '0041000000',
          '0041010000',
          '0032010000',
        ]);
      });
    },
  );

  test(
    'unverified protected reads are rejected and an explicit per-request PIN works',
    () async {
      // Firmware 2.0.0 gates the configuration read on-card: the PIN-less
      // read reuses the fresh selection and the card itself rejects it.
      final transport = _Transport(['6982', '9000', '9000', '0100010101019000']);
      await _prepared(transport, (client) async {
        await expectLater(client.readConfig(), _kind('SecurityStatusNotSatisfied'));
        expect(transport.commands, ['0042000000']);
        expect(await client.readConfig(pin: '123456'), [1, 0, 1, 1, 1, 1]);
        expect(transport.commands, [
          '0042000000',
          '${_select}00',
          '${_verify}00',
          '0042000000',
        ]);
      }, firmware: '2.0.0');
    },
  );

  test(
    'a verified session reuses its selection until a mutation ends the evidence',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '0100010101019000',
        '0100010101019000',
        '9000',
        '9000',
        '9000',
        '0100010101019000',
      ]);
      await _prepared(transport, (client) async {
        expect(await client.verifyPin('123456'), isTrue);
        // No SELECT/VERIFY: the recorded session authorizes Existing reads,
        // and a supplied PIN stays unused while the evidence is valid.
        expect(await client.readConfig(), [1, 0, 1, 1, 1, 1]);
        expect(await client.readConfig(pin: '000000'), [1, 0, 1, 1, 1, 1]);
        // A confirmed mutation ends the evidence without touching the profile.
        await client.changePin('654321', currentPin: '123456');
        expect(client.lastProgress!.confirmedWrites, 1);
        expect(client.lastProgress!.reprobeRequired, isFalse);
        // Later protected requests fall back to an explicit per-request PIN.
        expect(await client.readConfig(pin: '654321'), [1, 0, 1, 1, 1, 1]);
        expect(transport.commands, [
          '${_select}00',
          '${_verify}00',
          '0042000000',
          '0042000000',
          '002100000636353433323100',
          '${_select}00',
          '002000000636353433323100',
          '0042000000',
        ]);
      }, firmware: '2.0.0');
    },
  );

  test(
    'another applet selection on the lease ends the Admin session evidence',
    () async {
      final transport = _Transport([
        ..._probe('3.1.0'),
        '9000',
        '9000',
        ..._probe('3.1.0'),
        '9000',
        '0600009000',
        '01E00516E1531554E2E39000',
        '9000',
        '9000',
        '9000',
      ]);
      await CardSessions().run((session) async {
        session.bind(transport.transceive);
        final admin = AdminCardClient(
          transport: transport,
          lease: session.lease,
        );
        final piv = PivCardClient(transport: transport, lease: session.lease);
        await admin.prepare();
        transport.commands.clear();
        expect(await admin.verifyPin('123456'), isTrue);
        final verified = transport.commands.length;
        await piv.prepare();
        // PIV selection replaced the Admin selection; the next protected
        // request must SELECT and explicitly verify again.
        await admin.setNfcEnabled(false, pin: '123456');
        expect(transport.commands.sublist(0, verified), [_select, _verify]);
        expect(transport.commands.sublist(transport.commands.length - 3), [
          _select,
          _verify,
          '00140100',
        ]);
      });
    },
  );

  test(
    'a failed Existing request ends the session evidence conservatively',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '6982',
        '9000',
        '9000',
        '9000',
      ]);
      await _prepared(transport, (client) async {
        expect(await client.verifyPin('123456'), isTrue);
        await expectLater(
          client.readConfig(),
          _kind('SecurityStatusNotSatisfied'),
        );
        expect(transport.commands, [_select, _verify, '0042000000']);
        // The card rejected the session, so the evidence is dropped and the
        // next protected request SELECTs and verifies its explicit PIN.
        await client.setNfcEnabled(false, pin: '123456');
        expect(transport.commands, [
          _select,
          _verify,
          '0042000000',
          _select,
          _verify,
          '00140100',
        ]);
      });
    },
  );

  test(
    'configuration layout follows firmware instead of response length',
    () async {
      for (final entry in [
        ('1.3', '010101010001099000'),
        ('1.5.2', '01000101019000'),
        ('1.6.2', '0100010101019000'),
        ('3.0.3', '01FF000101FF9000'),
      ]) {
        await _prepared(_Transport(['9000', '9000', entry.$2]), (client) async {
          expect(
            await client.readConfig(pin: '123456'),
            hex.decode(entry.$2.substring(0, entry.$2.length - 4)),
          );
        }, firmware: entry.$1);
      }
      for (final response in ['0100019000', '02000001013F9000']) {
        await _prepared(_Transport(['9000', response]), (client) async {
          await expectLater(client.readConfig(), _kind('InvalidResponse'));
        });
      }
    },
  );

  test(
    'PIN input is UTF8, owned, bounded, and failed VERIFY never reaches a write',
    () async {
      final transport = _Transport(['9000', '63C2', '9000', '9000', '9000']);
      await _prepared(transport, (client) async {
        await expectLater(
          client.changePin('654321', currentPin: '123456'),
          _kind('AuthenticationFailed'),
        );
        expect(client.lastStatusWord, '63C2');
        expect(client.lastProgress!.confirmedWrites, 0);
        expect(transport.commands, [_select, _verify]);
        await client.changePin('CanoKey密码', currentPin: '123456');
        expect(transport.commands.last, '002100000D43616E6F4B6579E5AF86E7A081');
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
    'configuration patches preserve unselected fields and require fresh discovery after writes',
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
        expect(transport.commands, [
          _select,
          _verify,
          '0042000000',
          '00400100',
          '0040063F',
        ]);
        expect(client.lastProgress!.confirmedWrites, 2);
        expect(client.lastProgress!.reprobeRequired, isTrue);
        await expectLater(client.readConfig(), throwsStateError);
        await expectLater(client.readFirmwareVersion(), throwsStateError);
      });
    },
  );

  test(
    'partial configuration failure retains progress and never resumes or rolls back',
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
        expect(transport.commands, [
          _select,
          _verify,
          '0042000000',
          '00400100',
          '00400400',
        ]);
        await expectLater(client.readConfig(), throwsStateError);
      });
    },
  );

  test(
    'transport loss after exposing a write retains uncertainty before disposal',
    () async {
      final failure = StateError('lost write response');
      final transport = _Transport(
        ['9000', '9000', '01000001013F9000'],
        onCommand: (command) async {
          if (command == '00400100') throw failure;
        },
      );
      await _prepared(transport, (client) async {
        await expectLater(
          client.configure(pin: '123456', ledOn: false),
          throwsA(same(failure)),
        );
        expect(client.lastProgress!.confirmedWrites, 0);
        expect(client.lastProgress!.reprobeRequired, isTrue);
        expect(transport.commands, hasLength(4));
      });
    },
  );

  test(
    'cancellation drains the write and records exposed mutation without publishing success',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      final transport = _Transport(
        ['9000', '9000', '01000001013F9000', '9000'],
        onCommand: (command) async {
          if (command == '00400100') {
            started.complete();
            await finish.future;
          }
        },
      );
      await _prepared(transport, (client) async {
        final write = client.configure(pin: '123456', ledOn: false);
        final rejected = expectLater(write, throwsStateError);
        await started.future;
        await expectLater(client.prepare(), throwsStateError);
        await expectLater(client.readConfig(), throwsStateError);
        client.cancelPendingOperations();
        finish.complete();
        await rejected;
        expect(client.lastStatusWord, isNull);
        expect(client.lastProgress!.confirmedWrites, 0);
        expect(client.lastProgress!.reprobeRequired, isTrue);
        expect(transport.commands, hasLength(4));
      });
    },
  );

  test(
    'no-op patches keep profile evidence and never send a mutation',
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
        expect(transport.commands, [
          _select,
          _verify,
          '0042000000',
          _select,
          '0042000000',
        ]);
      });
    },
  );

  test(
    'unknown feature bits prevent all patch writes instead of overwriting them',
    () async {
      final transport = _Transport(['9000', '9000', '0100000101809000']);
      await _prepared(transport, (client) async {
        await expectLater(
          client.configure(
            pin: '123456',
            ledOn: false,
            featureMask: 1,
            featureValues: 1,
          ),
          _kind('UnsupportedProtocolVersion'),
        );
        expect(client.lastProgress!.reprobeRequired, isFalse);
        expect(transport.commands, [_select, _verify, '0042000000']);
      });
    },
  );

  test(
    'modern SM2 writes signed big-endian values with explicit authentication',
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
        expect(transport.commands, [
          _select,
          _verify,
          '0011000000',
          _select,
          _verify,
          '0011000000',
          '0012000008800000007FFFFFFF',
        ]);
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );

  test(
    'legacy SM2 uses explicit packed little-endian fields and retains enable flag',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '0109000000D0FFFFFF9000',
        '9000',
        '9000',
        '9000',
      ]);
      await _prepared(transport, (client) async {
        await client.writeSm2Config(
          pin: '123456',
          enabled: false,
          curveId: 10,
          algoId: -48,
        );
        expect(transport.commands, [
          '${_select}00',
          '${_verify}00',
          '0011000000',
          '${_select}00',
          '${_verify}00',
          '0012000009000A000000D0FFFFFF00',
        ]);
      }, firmware: '3.0.3');
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
      expect(transport.commands, [_select, _verify, '0011000000']);
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
    'NDEF reset and factory reset use distinct explicit authentication requirements',
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
        // Factory reset submits no PIN; a fresh selection skips the SELECT.
        expect(transport.commands, ['00500000055245534554']);
        expect(client.lastProgress!.reprobeRequired, isTrue);
      });
    },
  );

  test(
    'malformed mutation acknowledgments and 6C responses are not replayed',
    () async {
      for (final response in ['019000', '6C00']) {
        final transport = _Transport(['9000', '9000', response]);
        await _prepared(transport, (client) async {
          await expectLater(
            client.setNfcEnabled(false, pin: '123456'),
            throwsA(isA<ProtocolException>()),
          );
          expect(transport.commands, [_select, _verify, '00140100']);
          expect(client.lastProgress!.reprobeRequired, isTrue);
          expect(client.lastProgress!.confirmedWrites, 0);
        });
      }
    },
  );

  test(
    'shared lease invalidates PIV selection and all profiles after Admin writes',
    () async {
      final transport = _Transport([
        ..._probe('3.1.0'),
        ..._probe('3.1.0'),
        ..._probe('3.1.0'),
        '9000',
        '0600009000',
        '01E00516E1531554E2E39000',
        '9000',
        'AABB9000',
        '9000',
        '9000',
        '01000001013F9000',
        '9000',
      ]);
      await CardSessions().run((session) async {
        session.bind(transport.transceive);
        final admin = AdminCardClient(
          transport: transport,
          lease: session.lease,
        );
        final other = AdminCardClient(
          transport: transport,
          lease: session.lease,
        );
        final piv = PivCardClient(transport: transport, lease: session.lease);
        await admin.prepare();
        await other.prepare();
        await piv.prepare();
        expect(await admin.readChipId(), 'AABB');
        final afterRead = transport.commands.length;
        await expectLater(piv.readMetadata(0x80), throwsStateError);
        await expectLater(piv.readVersion(), throwsStateError);
        await expectLater(piv.readCertificate(5), throwsStateError);
        expect(transport.commands, hasLength(afterRead));
        await admin.configure(pin: '123456', ledOn: false);
        final afterWrite = transport.commands.length;
        await expectLater(other.readConfig(), throwsStateError);
        expect(transport.commands, hasLength(afterWrite));
      });
    },
  );

  test(
    'profiles expire on session release and failed reprobe cannot restore them',
    () async {
      final transport = _Transport([..._probe('3.1.0'), '6F00']);
      final client = AdminCardClient(transport: transport);
      await client.withSession(() async {
        await client.prepare();
        await expectLater(client.prepare(), throwsA(isA<ProtocolException>()));
        await expectLater(client.readConfig(), throwsStateError);
      });
      await client.withSession(() async {
        await expectLater(client.verifyPin('123456'), throwsStateError);
      });
    },
  );
}

const _select = '00A4040005F000000000';
const _verify = '0020000006313233343536';
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
    expect(transport.commands, [
      '${_select}00',
      '0031000000',
      '0031010000',
      '0032000000',
    ]);
    transport.commands.clear();
    return body(client);
  });
}

class _Transport implements ApduTransport {
  _Transport(List<String> responses, {this.onCommand})
    : responses = List.of(responses);
  final Future<void> Function(String)? onCommand;
  final List<String> responses;
  final List<String> commands = [];
  @override
  Future<String> transceive(String command) async {
    commands.add(command);
    await onCommand?.call(command);
    return responses.removeAt(0);
  }
}
