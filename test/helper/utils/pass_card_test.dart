@Tags(['native'])
library;

import 'dart:convert';

import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/pass_card.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test(
    'reads typed slots, preserving OATH references and unknown states',
    () async {
      final transport = _Transport([
        '9000',
        // Short = static with Enter; long = OATH credential "test" without Enter.
        '0201010474657374009000',
        '9000',
        // Short = unknown type 0x7F carried verbatim; long = off.
        '7F009000',
      ]);
      await _prepared(transport, (client) async {
        final slots = await client.readSlots();
        expect(slots, hasLength(2));
        expect(slots[0].type, PassSlotType.static);
        expect(slots[0].withEnter, isTrue);
        expect(slots[1].type, PassSlotType.oath);
        expect(slots[1].name, 'test');
        expect(slots[1].withEnter, isFalse);

        final unknown = await client.readSlots();
        expect(unknown[0].type, PassSlotType.unknown);
        expect(unknown[1].type, PassSlotType.none);

        // A PIN-less read SELECTs but never verifies.
        expect(transport.commands, [
          _select,
          '0043000000',
          _select,
          '0043000000',
        ]);
      });
    },
  );

  test('reads verify the supplied PIN on gated firmware', () async {
    final transport = _Transport([
      '9000',
      '9000',
      // Both slots off.
      '00009000',
    ]);
    await _prepared(transport, (client) async {
      final slots = await client.readSlots(pin: '123456');
      expect(slots.every((slot) => slot.type == PassSlotType.none), isTrue);
      expect(transport.commands, [_select, _verify, '0043000000']);
    });
  });

  test('malformed slot dumps fail instead of fabricating slots', () async {
    final transport = _Transport(['9000', '029000']);
    await _prepared(transport, (client) async {
      await expectLater(client.readSlots(), _kind('InvalidResponse'));
      expect(transport.commands, [_select, '0043000000']);
    });
  });

  test(
    'static writes authenticate per request and invalidate profile evidence',
    () async {
      final transport = _Transport(['9000', '9000', '9000']);
      await _prepared(transport, (client) async {
        expect(
          await client.setSlot(
            1,
            PassSlotType.static,
            'pw',
            true,
            pin: '123456',
          ),
          isTrue,
        );
        expect(client.lastStatusWord, '9000');
        expect(client.lastProgress!.confirmedWrites, 1);
        expect(client.lastProgress!.reprobeRequired, isTrue);
        expect(transport.commands, [_select, _verify, '00440100050202707701']);
        // The write invalidates profile evidence until an explicit reprobe.
        await expectLater(client.readSlots(), throwsStateError);
      });
    },
  );

  test(
    'off and HMAC-SHA1 writes re-probe after each profile-invalidating slot',
    () async {
      final transport = _Transport([
        '9000',
        '9000',
        '9000',
        ..._probeResponses('3.1.0'),
        '9000',
        '9000',
        '9000',
      ]);
      await _prepared(transport, (client) async {
        expect(
          await client.setSlot(2, PassSlotType.none, '', false, pin: '123456'),
          isTrue,
        );
        expect(transport.commands, [_select, _verify, '004402000100']);
        transport.commands.clear();

        await client.prepare();
        expect(transport.commands, [
          '00A4040005F00000000000',
          '0031000000',
          '0031010000',
          '0032000000',
        ]);
        transport.commands.clear();

        final key = List<int>.filled(20, 0x09);
        expect(
          await client.setSlot(
            1,
            PassSlotType.hmacSha1,
            hex.encode(key),
            false,
            pin: '123456',
          ),
          isTrue,
        );
        expect(transport.commands, [
          _select,
          _verify,
          '00440100160314${hex.encode(key)}',
        ]);
      });
    },
  );

  test(
    'credential rejections keep the status word and never reach the write',
    () async {
      final transport = _Transport(['9000', '63C2', '9000', '6983']);
      await _prepared(transport, (client) async {
        expect(
          await client.setSlot(
            1,
            PassSlotType.static,
            'pw',
            false,
            pin: '123456',
          ),
          isFalse,
        );
        expect(client.lastStatusWord, '63C2');
        expect(
          await client.setSlot(
            1,
            PassSlotType.static,
            'pw',
            false,
            pin: '123456',
          ),
          isFalse,
        );
        expect(client.lastStatusWord, '6983');
        expect(transport.commands, [_select, _verify, _select, _verify]);
      });
    },
  );

  test(
    'a full slot store keeps its status word and is never replayed',
    () async {
      final transport = _Transport(['9000', '9000', '6A84']);
      await _prepared(transport, (client) async {
        await expectLater(
          client.setSlot(1, PassSlotType.static, 'pw', false, pin: '123456'),
          _kind('UnexpectedStatusWord'),
        );
        expect(client.lastStatusWord, '6A84');
        expect(client.lastProgress!.confirmedWrites, 0);
        expect(client.lastProgress!.reprobeRequired, isTrue);
        expect(transport.commands, [_select, _verify, '00440100050202707700']);
      });
    },
  );

  test('invalid slots, types and secrets fail before any I/O', () async {
    final transport = _Transport([]);
    await _prepared(transport, (client) async {
      await expectLater(
        client.setSlot(0, PassSlotType.none, '', false, pin: '123456'),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(3, PassSlotType.none, '', false, pin: '123456'),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(
          1,
          PassSlotType.static,
          'pässword',
          false,
          pin: '123456',
        ),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(1, PassSlotType.static, 'x' * 33, false, pin: '123456'),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(
          1,
          PassSlotType.hmacSha1,
          'zz' * 20,
          false,
          pin: '123456',
        ),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(
          1,
          PassSlotType.hmacSha1,
          '09' * 19,
          false,
          pin: '123456',
        ),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(1, PassSlotType.oath, '', false, pin: '123456'),
        throwsArgumentError,
      );
      await expectLater(
        client.setSlot(1, PassSlotType.unknown, '', false, pin: '123456'),
        throwsArgumentError,
      );
      expect(transport.commands, isEmpty);
    });
  });

  test(
    'a pass probe after Admin verification ends the shared session evidence',
    () async {
      final transport = _Transport([
        ..._probeResponses('3.1.0'),
        '9000',
        '9000',
        ..._probeResponses('3.1.0'),
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
        final pass = PassCardClient(transport: transport, lease: session.lease);
        await admin.prepare();
        expect(await admin.verifyPin('123456'), isTrue);
        // The pass client's own probe re-selects Admin on the shared lease,
        // which ends the recorded session; the protected write falls back to
        // its explicit per-request PIN.
        await pass.prepare();
        expect(
          await pass.setSlot(1, PassSlotType.static, 'pw', true, pin: '123456'),
          isTrue,
        );
        expect(transport.commands, [
          '00A4040005F00000000000',
          '0031000000',
          '0031010000',
          '0032000000',
          _select,
          _verify,
          '00A4040005F00000000000',
          '0031000000',
          '0031010000',
          '0032000000',
          _select,
          _verify,
          '00440100050202707701',
        ]);
      });
    },
  );

  test('operations require an explicitly prepared lease', () async {
    final transport = _Transport([]);
    final client = PassCardClient(transport: transport);
    await client.withSession(() async {
      await expectLater(client.readSlots(), throwsStateError);
      await expectLater(
        client.setSlot(1, PassSlotType.none, '', false, pin: '123456'),
        throwsStateError,
      );
    });
    expect(transport.commands, isEmpty);
  });
}

const _select = '00A4040005F000000000';
const _verify = '0020000006313233343536';

List<String> _probeResponses(String firmware) => [
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
  Future<T> Function(PassCardClient) body, {
  String firmware = '3.1.0',
}) async {
  transport.responses.insertAll(0, _probeResponses(firmware));
  final client = PassCardClient(transport: transport);
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
  _Transport(List<String> responses) : responses = List.of(responses);

  final List<String> responses;
  final List<String> commands = [];

  @override
  Future<String> transceive(String command) async {
    commands.add(command);
    if (responses.isEmpty) {
      throw StateError('No queued APDU response for $command');
    }
    return responses.removeAt(0);
  }
}
