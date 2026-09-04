import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/pass_card.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('configures and reads Pass slots through the injected transport',
      () async {
    final transport = _QueueApduTransport(['9000', '0201009000']);
    final client = PassCardClient(transport: transport);

    expect(
      await client.setSlot(1, PassSlotType.static, 'test', true),
      isTrue,
    );
    final slots = await client.readSlots();

    expect(transport.commands, [
      '004401000702047465737401',
      '0043000000',
    ]);
    expect(slots, hasLength(2));
    expect(slots.first.type, PassSlotType.static);
    expect(slots.first.withEnter, isTrue);
    expect(slots.last.type, PassSlotType.none);
  });

  test('encodes empty and HMAC-SHA1 slots and reports card errors', () async {
    final transport = _QueueApduTransport(['9000', '6982']);
    final client = PassCardClient(transport: transport);
    const secret = '0000000000000000000000000000000000000000';

    expect(await client.setSlot(2, PassSlotType.none, '', false), isTrue);
    expect(
      await client.setSlot(1, PassSlotType.hmacSha1, secret, false),
      isFalse,
    );
    expect(client.lastStatusWord, '6982');
    expect(transport.commands[0], '004402000100');
    expect(transport.commands[1], '00440100160314$secret');
    expect(
      () => client.setSlot(1, PassSlotType.oath, '', false),
      throwsArgumentError,
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
