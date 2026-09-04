import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs PIV metadata and PIN operations through the injected transport',
      () async {
    final transport = _QueueApduTransport([
      '9000',
      '0102039000',
      '010203049000',
      '63C3',
      '9000',
      '9000',
      '9000',
      '0101FF050101060203039000',
    ]);
    final client = PivCardClient(transport: transport);

    await client.select();
    expect(await client.readVersion(), [1, 2, 3]);
    expect(await client.readSerial(), '01020304');
    expect(await client.readPinRetries(), '63C3');
    expect(await client.verifyPin('123456'), isTrue);
    expect(await client.changePin('123456', '654321'), isTrue);
    await client.logout();
    final metadata = await client.readMetadata(0x80);

    expect(metadata, isNotNull);
    expect(metadata!.retriesCount, 3);
    expect(metadata.remainingCount, 3);
    expect(transport.commands, [
      '00A4040005A000000308',
      '00FD000000',
      '00F8000000',
      '0020008000',
      '0020008008313233343536FFFF',
      '0024008010313233343536FFFF363534333231FFFF',
      '0020FF8000',
      '00F7008000',
    ]);
  });

  test('reads optional algorithm extensions and missing metadata', () async {
    final config = await PivCardClient(
      transport: _QueueApduTransport([
        '9000',
        '01E00516E1531554E2E39000',
      ]),
    ).readAlgorithmExtensions();
    expect(config, isNotNull);
    expect(config!.enabled, isTrue);

    expect(
      await PivCardClient(
        transport: _QueueApduTransport(['9000', '6D00']),
      ).readAlgorithmExtensions(),
      isNull,
    );
    expect(
      await PivCardClient(
        transport: _QueueApduTransport(['6A88']),
      ).readMetadata(0x80),
      isNull,
    );
  });

  test('follows metadata GET RESPONSE and validates PIN length', () async {
    final transport = _QueueApduTransport([
      '0101FF6104',
      '050101060203039000',
    ]);
    final client = PivCardClient(transport: transport);

    final metadata = await client.readMetadata(0x80);

    expect(metadata, isNotNull);
    expect(transport.commands, ['00F7008000', '00C0000004']);
    expect(() => client.verifyPin('123456789'), throwsArgumentError);
  });

  test('maps metadata with firmware-specific algorithm extensions', () async {
    final metadata = await PivCardClient(
      transport: _QueueApduTransport(['010122050101060203039000']),
    ).readMetadata(
      0x80,
      algorithmExtensionConfig: PivAlgorithmExtensionConfig.legacyV2,
    );

    expect(metadata, isNotNull);
    expect(metadata!.algorithm, AlgorithmType.ed25519);
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
