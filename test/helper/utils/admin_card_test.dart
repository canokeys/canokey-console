import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
