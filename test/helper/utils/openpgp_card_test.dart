@Tags(['native'])
library;

import 'dart:convert';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

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

  test('legacy firmware leaves the touch cache time absent', () async {
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
  });

  test('changes the user PIN through libcanokey', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    await _withPreparedClient(transport, (client) async {
      expect(await client.changeUserPin('123456', '654321'), isTrue);
      expect(client.lastStatusWord, '9000');
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
    });
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
    });
  });
}

List<int> _tlv(int tag, List<int> value) {
  final tagBytes = tag <= 0xFF ? [tag] : [tag >> 8, tag & 0xFF];
  return [...tagBytes, value.length, ...value];
}

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
    return action(client);
  });
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(List<String> responses) : responses = List.of(responses);

  final List<String> responses;
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    if (_responseIndex >= responses.length) {
      throw StateError('No queued APDU response for $capdu');
    }
    return responses[_responseIndex++];
  }
}
