import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds OATH operations and follows calculate-all pagination', () async {
    final transport = _QueueApduTransport([
      '79030600007101019000',
      '9000',
      '7605000000019000',
      '9000',
      '7101416102',
      '7605000000019000',
      '6985',
    ]);
    final client = OathCardClient(transport: transport);

    final selection = await client.select();
    expect(selection.version, OathVersion.v2);
    expect(
      await client.put(
        name: 'A',
        secretHex: '0102',
        type: OathType.totp,
        algorithm: OathAlgorithm.sha1,
        digits: 6,
      ),
      '9000',
    );
    expect(
      await client.calculate(
        name: 'A',
        type: OathType.totp,
        challengeHex: '0000000000000001',
      ),
      '7605000000019000',
    );
    expect(await client.delete('A'), '9000');
    expect(
      await client.calculateAll('0000000000000001'),
      '7101417605000000019000',
    );

    expect(transport.commands, [
      '00A4040007A0000005272101',
      '0001000009710141730421060102',
      '00A200010d71014174080000000000000001',
      '0002000003710141',
      '00A400010a74080000000000000001',
      '00A50000FF',
      '00A50000FF',
    ]);
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
