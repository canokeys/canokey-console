import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frames CTAP commands and follows GET RESPONSE', () async {
    final transport = _QueueApduTransport(['006102', 'A19000']);
    final transmitter = CtapTransimtter(transport: transport);

    final response = await transmitter.transceive([0x04]);

    expect(response.status, 0);
    expect(response.data, [0xA1]);
    expect(transport.commands, ['801000000104', '80C0000002']);
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
