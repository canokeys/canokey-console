import 'dart:convert';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the injected transport and follows GET RESPONSE', () async {
    final transport = _QueueApduTransport(['6102', '9000']);
    final client = OpenPgpCardClient(transport: transport);

    await client.select();

    expect(
      transport.commands,
      ['00A4040006D27600012401', '00C0000002'],
    );
    expect(client.lastStatusWord, '9000');
  });

  test('changes the user PIN through the injected transport', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    final client = OpenPgpCardClient(transport: transport);

    final changed = await client.changeUserPin('123456', '654321');

    expect(changed, isTrue);
    expect(
      transport.commands,
      [
        '00A4040006D27600012401',
        '002400810c313233343536363534333231',
      ],
    );
  });

  test('parses card info with optional legacy data objects missing', () async {
    const aid = 'D2760001240103040000010203040000';
    const application = '4F10${aid}C40700000000030303';
    final transport = _QueueApduTransport([
      '9000',
      '${application}9000',
      '6A88',
      '6A88',
      '6A88',
    ]);
    final client = OpenPgpCardClient(transport: transport);

    final info = await client.readCardInfo();

    expect(info.version, '3.4');
    expect(info.serialNumber, '01020304');
    expect(info.pinState.userRetries, 3);
    expect(info.pinState.adminRetries, 3);
    expect(info.keySlots.keys, containsAll(OpenPgpKeyType.values));
    expect(info.keySlots.values.every((slot) => !slot.hasKey), isTrue);
    expect(info.touchCacheTime, isNull);
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
      '${hex.encode(holder)}9000',
      '${hex.encode(utf8.encode('https://example.test/key'))}9000',
      '0F9000',
    ]);

    final info = await OpenPgpCardClient(transport: transport).readCardInfo();

    expect(info.manufacturer, 'Yubico');
    expect(info.cardHolder, 'Alice Example');
    expect(info.publicKeyUrl, 'https://example.test/key');
    expect(info.touchCacheTime, 15);
    expect(info.pinState.signaturePinForced, isTrue);
    expect(info.keySlots[OpenPgpKeyType.signature]!.fingerprint,
        '0102030405060708090A0B0C0D0E0F1011121314');
    expect(info.keySlots[OpenPgpKeyType.signature]!.generatedAt,
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true));
    expect(info.keySlots[OpenPgpKeyType.signature]!.touchFixed, isTrue);
    expect(info.keySlots[OpenPgpKeyType.encryption]!.fingerprint, isNull);
    expect(info.keySlots[OpenPgpKeyType.encryption]!.touchFixed, isFalse);
    expect(info.keySlots[OpenPgpKeyType.authentication]!.hasKey, isTrue);
    expect(info.keySlots[OpenPgpKeyType.authentication]!.touchFixed, isTrue);
  });

  test('builds OpenPGP administration operations', () async {
    final transport = _QueueApduTransport(List.filled(20, '9000'));
    final client = OpenPgpCardClient(transport: transport);

    expect(await client.setResetCode('12345678', '12345678'), isTrue);
    expect(await client.setPinRetries('12345678', 3, 3, 3), isTrue);
    expect(await client.setSignaturePinPolicy('12345678', true), isTrue);
    expect(await client.unblockUserPinWithAdmin('12345678', '123456'), isTrue);
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

    expect(
      transport.commands.any((command) => command.startsWith('00DA00d3')),
      isTrue,
    );
    expect(transport.commands, contains('00F2000003030303'));
    expect(transport.commands, contains('00DA00c40100'));
    expect(transport.commands, contains('002C028106313233343536'));
    expect(
      transport.commands,
      contains('002C00810e3132333435363738313233343536'),
    );
    expect(transport.commands, contains('00DA00d6020120'));
    expect(transport.commands, contains('00DA0102010f'));
  });

  test('stops an admin operation when PIN verification fails', () async {
    final transport = _QueueApduTransport(['9000', '6982']);
    final client = OpenPgpCardClient(transport: transport);

    expect(await client.setResetCode('bad', '12345678'), isFalse);
    expect(transport.commands, hasLength(2));
    expect(client.lastStatusWord, '6982');
  });

  test('changes the admin PIN and uses extended APDU lengths', () async {
    final transport = _QueueApduTransport(List.filled(5, '9000'));
    final client = OpenPgpCardClient(transport: transport);

    expect(await client.changeAdminPin('12345678', '87654321'), isTrue);
    expect(
      await client.setResetCode('12345678', List.filled(256, 'A').join()),
      isTrue,
    );

    expect(transport.commands[1], startsWith('0024008310'));
    expect(transport.commands[4], startsWith('00DA00d3000100'));
  });
}

List<int> _tlv(int tag, List<int> value) {
  final tagBytes = tag <= 0xFF ? [tag] : [tag >> 8, tag & 0xFF];
  return [...tagBytes, value.length, ...value];
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(this.responses);

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
