@Tags(['native'])
library;

import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/ndef_card.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

const _selectApplet = '00A4040007D2760000850101';
const _selectCc = '00A4000C02E103';
const _selectNdef = '00A4000C020001';
const _readCc = '00B000000F';
const _readNlen = '00B0000002';

/// 15-byte capability container for a writable file of [fileSize] bytes.
List<int> _capabilityContainer(int fileSize, {bool readOnly = false}) => [
  0x00, 0x0f, 0x20, 0x00, 0xf0, 0x00, 0xf0, //
  0x04, 0x06, 0xe1, 0x04,
  fileSize >> 8, fileSize & 0xff, 0x00, readOnly ? 0xff : 0x00,
];

String _ok(List<int> data) => '${hex.encode(data)}9000';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('reads capability and message through the libcanokey machines', () async {
    final cc = _capabilityContainer(5); // max message length 3
    final transport = _QueueApduTransport([
      '9000', '9000', _ok(cc), // read capability
      '9000', '9000', _ok(cc), '9000', _ok([0, 3]), _ok([1, 2, 3]), // read
    ]);
    await _withClient(transport, (client) async {
      final data = await client.read();

      expect(data, isNotNull);
      expect(data!.maxMessageLength, 3);
      expect(data.readOnly, isFalse);
      expect(data.message, [1, 2, 3]);
      expect(transport.commands, [
        _selectApplet, _selectCc, _readCc,
        _selectApplet, _selectCc, _readCc, _selectNdef, _readNlen,
        '00B0000203',
      ]);
    });
  });

  test('reads an empty message without further message reads', () async {
    final cc = _capabilityContainer(1024, readOnly: true);
    final transport = _QueueApduTransport([
      '9000', '9000', _ok(cc),
      '9000', '9000', _ok(cc), '9000', _ok([0, 0]),
    ]);
    await _withClient(transport, (client) async {
      final data = await client.read();

      expect(data, isNotNull);
      expect(data!.maxMessageLength, 1022);
      expect(data.readOnly, isTrue);
      expect(data.message, isEmpty);
      expect(transport.commands, [
        _selectApplet, _selectCc, _readCc,
        _selectApplet, _selectCc, _readCc, _selectNdef, _readNlen,
      ]);
    });
  });

  test('writes zero NLEN, 240-byte chunks and the real NLEN last', () async {
    final transport = _QueueApduTransport(List.filled(6, '9000'));
    final message = Uint8List.fromList(List.generate(241, (index) => index));
    await _withClient(transport, (client) async {
      expect(await client.write(message), isTrue);

      expect(transport.commands, [
        _selectApplet,
        _selectNdef,
        '00D60000020000',
        '00D60002F0${hex.encode(message.sublist(0, 240)).toUpperCase()}',
        '00D600F201F0',
        '00D600000200F1',
      ]);
    });
  });

  test('writes an empty message as two NLEN updates', () async {
    final transport = _QueueApduTransport(List.filled(4, '9000'));
    await _withClient(transport, (client) async {
      expect(await client.write(Uint8List(0)), isTrue);
      expect(transport.commands, [
        _selectApplet,
        _selectNdef,
        '00D60000020000',
        '00D60000020000',
      ]);
    });
  });

  test('reports an absent NDEF applet as unavailable', () async {
    await _withClient(_QueueApduTransport(['6A82']), (client) async {
      expect(await client.read(), isNull);
    });
    await _withClient(_QueueApduTransport(['6A82']), (client) async {
      expect(await client.write(Uint8List.fromList([1])), isFalse);
    });
  });

  test('maps a 6982 write rejection to NdefReadOnlyException', () async {
    final transport = _QueueApduTransport(['9000', '9000', '6982']);
    await _withClient(transport, (client) async {
      await expectLater(
        client.write(Uint8List.fromList([1])),
        throwsA(isA<NdefReadOnlyException>()),
      );
      // The failed write stopped at the zero-NLEN update; nothing is replayed.
      expect(transport.commands, [
        _selectApplet,
        _selectNdef,
        '00D60000020000',
      ]);
    });
  });

  test('rejects a malformed capability container', () async {
    final transport = _QueueApduTransport([
      '9000', '9000', _ok(List.filled(15, 0)),
    ]);
    await _withClient(transport, (client) async {
      await expectLater(
        client.read(),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'InvalidResponse')
            .having((e) => e.details.phase, 'phase', 'Parsing')),
      );
    });
  });

  test('rejects an NLEN beyond the capability limit before reading', () async {
    final cc = _capabilityContainer(3); // max message length 1
    final transport = _QueueApduTransport([
      '9000', '9000', _ok(cc),
      '9000', '9000', _ok(cc), '9000', _ok([0, 2]),
    ]);
    await _withClient(transport, (client) async {
      await expectLater(
        client.read(),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'InvalidResponse')),
      );
      expect(transport.commands, [
        _selectApplet, _selectCc, _readCc,
        _selectApplet, _selectCc, _readCc, _selectNdef, _readNlen,
      ]);
    });
  });

  test('rejects an oversized message before any I/O', () async {
    final transport = _QueueApduTransport([]);
    await _withClient(transport, (client) async {
      await expectLater(
        client.write(Uint8List(1023)),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'InvalidArgument')),
      );
      expect(transport.commands, isEmpty);
    });
  });

  test('injected transports require an explicit session', () async {
    final client = NdefCardClient(transport: _QueueApduTransport([]));
    await expectLater(client.read(), throwsStateError);
  });
}

Future<T> _withClient<T>(
  _QueueApduTransport transport,
  Future<T> Function(NdefCardClient) action,
) {
  final client = NdefCardClient(transport: transport);
  return client.withSession(() => action(client));
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
