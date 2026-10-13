@Tags(['native'])
library;

import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/ndef_card.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

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
    });
  });

  test('writes a chunked message through the libcanokey machines', () async {
    final cc = _capabilityContainer(1024);
    final transport = _QueueApduTransport([
      '9000', '9000', _ok(cc), // capability preflight
      '9000', '9000', '9000', '9000', '9000',
    ]);
    final message = Uint8List.fromList(List.generate(241, (index) => index));
    await _withClient(transport, (client) async {
      expect(await client.write(message), isTrue);
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

  test('maps a read-only capability container to NdefReadOnlyException', () async {
    final cc = _capabilityContainer(1024, readOnly: true);
    final transport = _QueueApduTransport(['9000', '9000', _ok(cc)]);
    await _withClient(transport, (client) async {
      await expectLater(
        client.write(Uint8List.fromList([1])),
        throwsA(isA<NdefReadOnlyException>()),
      );
    });
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
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    return responses[_responseIndex++];
  }
}
