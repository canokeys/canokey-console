import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads current SM2 defaults and writes big-endian signed IDs', () async {
    final transport = _QueueApduTransport([
      '00000009ffffffca9000',
      '00000009ffffffca9000',
      '9000',
    ]);
    final client = AdminCardClient(transport: transport);
    final config = await client.readSm2Config();
    expect(config.enabled, isTrue);
    expect(config.canChangeEnabled, isFalse);
    expect(config.curveId, 9);
    expect(config.algoId, -54);
    await client.writeSm2Config(
        enabled: false, curveId: -2147483648, algoId: 2147483647);
    expect(transport.commands, [
      '0011000000',
      '0011000000',
      '0012000008800000007fffffff',
    ]);
  });

  test('preserves the legacy enabled byte when writing SM2 configuration',
      () async {
    final transport = _QueueApduTransport(['0100000009ffffffd09000', '9000']);
    final client = AdminCardClient(transport: transport);
    await client.writeSm2Config(enabled: false, curveId: 9, algoId: -48);
    expect(transport.commands, ['0011000000', '00120000090000000009ffffffd0']);
  });

  test('rejects reserved current SM2 IDs before sending a write', () async {
    final transport = _QueueApduTransport(['00000009ffffffca9000']);
    await expectLater(
      AdminCardClient(transport: transport)
          .writeSm2Config(enabled: true, curveId: 1, algoId: -54),
      throwsArgumentError,
    );
    expect(transport.commands, ['0011000000']);
  });

  test('rejects failed and malformed SM2 reads', () async {
    await expectLater(
        AdminCardClient(transport: _QueueApduTransport(['6982']))
            .readSm2Config(),
        throwsA(anything));
    await expectLater(
        AdminCardClient(transport: _QueueApduTransport(['00009000']))
            .readSm2Config(),
        throwsFormatException);
  });

  test('reads and updates admin data through the injected transport', () async {
    final transport = _QueueApduTransport([
      '9000',
      '9000',
      '312E339000',
      '434B9000',
      '010203049000',
      'AABB9000',
      '0100019000',
      '019000',
      '01029000',
      '9000',
    ]);
    final client = AdminCardClient(transport: transport);

    await client.select();
    expect(await client.verifyPin('123456'), isTrue);
    expect(await client.readFirmwareVersion(), '1.3');
    expect(await client.readModel(), 'CK');
    expect(await client.readSerial(), '01020304');
    expect(await client.readChipId(), 'AABB');
    expect(await client.readConfig(), [1, 0, 1]);
    expect(await client.readNfcEnabled(), isTrue);
    final storage = await client.readStorageUsage();
    expect(storage.usedKiB, 1);
    expect(storage.totalKiB, 2);
    await client.writeConfigByte(1, 0);

    expect(transport.commands, [
      '00A4040005F000000000',
      '0020000006313233343536',
      '0031000000',
      '0031010000',
      '0032000000',
      '0032010000',
      '0042000000',
      '0014000000',
      '0041000002',
      '00400100',
    ]);
  });

  test('runs optional admin operations and handles unavailable core commit',
      () async {
    final transport = _QueueApduTransport(List.filled(5, '9000'));
    final client = AdminCardClient(transport: transport);

    await client.setNfcEnabled(true);
    await client.setNfcEnabled(false);
    await client.setNdefReadOnly(true);
    await client.setNdefReadOnly(false);
    await client.resetNdef();

    expect(transport.commands, [
      '00140101',
      '00140100',
      '00080100',
      '00080000',
      '00070000',
    ]);
    expect(
      await AdminCardClient(
        transport: _QueueApduTransport(['6162639000']),
      ).readCoreCommit(),
      'abc',
    );
    expect(
      await AdminCardClient(
        transport: _QueueApduTransport(['9000']),
      ).readCoreCommit(),
      isNull,
    );
    expect(
      await AdminCardClient(
        transport: _QueueApduTransport(['6D00']),
      ).readCoreCommit(),
      isNull,
    );
  });

  test('encodes admin PIN operations as UTF-8 bytes', () async {
    final transport = _QueueApduTransport(['9000', '9000']);
    final client = AdminCardClient(transport: transport);

    expect(await client.verifyPin('CanoKey密码'), isTrue);
    await client.changePin('CanoKey密码');

    expect(transport.commands, [
      '002000000d43616e6f4b6579e5af86e7a081',
      '002100000d43616e6f4b6579e5af86e7a081',
    ]);
  });

  test('rejects admin PINs that exceed short APDU length', () async {
    final transport = _QueueApduTransport([]);
    final client = AdminCardClient(transport: transport);
    final pin = List.filled(64, '\u{1F600}').join();

    await expectLater(client.verifyPin(pin), throwsArgumentError);
    await expectLater(client.changePin(pin), throwsArgumentError);
    expect(transport.commands, isEmpty);
  });

  test('rejects invalid admin response data and configuration indexes',
      () async {
    final client = AdminCardClient(transport: _QueueApduTransport([]));

    expect(() => client.writeConfigByte(-1, 0), throwsRangeError);
    expect(() => client.writeConfigByte(1, 256), throwsRangeError);
    expect(
      AdminCardClient(
        transport: _QueueApduTransport(['029000']),
      ).readNfcEnabled(),
      throwsFormatException,
    );
    expect(
      AdminCardClient(
        transport: _QueueApduTransport(['019000']),
      ).readStorageUsage(),
      throwsFormatException,
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
