import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/ndef_card.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads capability and message data through the injected transport',
      () async {
    final capability = [
      0x00,
      0x0f,
      0x20,
      0x00,
      0xf0,
      0x00,
      0xf0,
      0x04,
      0x06,
      0xe1,
      0x04,
      0x00,
      0x05,
      0x00,
      0x00,
    ];
    final transport = _QueueApduTransport([
      '9000',
      '9000',
      '${hex.encode(capability)}9000',
      '9000',
      '00039000',
      '0102039000',
    ]);
    final client = NdefCardClient(transport: transport);

    final data = await client.read();

    expect(data, isNotNull);
    expect(data!.maxMessageLength, 3);
    expect(data.readOnly, isFalse);
    expect(data.message, [1, 2, 3]);
    expect(
      transport.commands,
      [
        '00A4040007D2760000850101',
        '00A4000C02E103',
        '00B000000F',
        '00A4000C020001',
        '00B0000002',
        '00B0000203',
      ],
    );
  });

  test('writes messages in production-sized chunks and commits NLEN last',
      () async {
    final transport = _QueueApduTransport(List.filled(6, '9000'));
    final client = NdefCardClient(transport: transport);
    final message = Uint8List.fromList(List.generate(241, (index) => index));

    expect(await client.write(message), isTrue);

    expect(transport.commands[2], '00D60000020000');
    expect(transport.commands[3].startsWith('00D60002F0'), isTrue);
    expect(transport.commands[4], '00D600F201F0');
    expect(transport.commands[5], '00D600000200F1');
  });

  test('reports unavailable and read-only NDEF applets', () async {
    expect(
      await NdefCardClient(
        transport: _QueueApduTransport(['6A82']),
      ).read(),
      isNull,
    );
    expect(
      await NdefCardClient(
        transport: _QueueApduTransport(['6A82']),
      ).write(Uint8List.fromList([1])),
      isFalse,
    );
    expect(
      NdefCardClient(
        transport: _QueueApduTransport(['9000', '9000', '6982']),
      ).write(Uint8List.fromList([1])),
      throwsA(isA<NdefReadOnlyException>()),
    );
  });

  test('rejects malformed capability and oversized message lengths', () async {
    expect(
      NdefCardClient(
        transport: _QueueApduTransport([
          '9000',
          '9000',
          '${hex.encode(List.filled(15, 0))}9000',
        ]),
      ).read(),
      throwsFormatException,
    );

    final capability = List<int>.filled(15, 0)
      ..[7] = 0x04
      ..[8] = 0x06
      ..[12] = 0x03;
    expect(
      NdefCardClient(
        transport: _QueueApduTransport([
          '9000',
          '9000',
          '${hex.encode(capability)}9000',
          '9000',
          '00029000',
        ]),
      ).read(),
      throwsFormatException,
    );
  });

  test('rejects invalid short APDU ranges', () {
    expect(() => NdefCardClient.readBinaryApdu(-1, 1), throwsRangeError);
    expect(
      () => NdefCardClient.updateBinaryApdu(0, Uint8List(0)),
      throwsRangeError,
    );
  });
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(this.responses);

  final List<String> responses;
  final List<String> commands = [];
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses[_responseIndex++];
  }
}
