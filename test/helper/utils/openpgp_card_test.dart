import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
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
