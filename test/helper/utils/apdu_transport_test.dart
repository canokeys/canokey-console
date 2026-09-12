import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'collects all response fragments and preserves the terminal status',
    () async {
      final transport = _Transport(['aa6100', 'bb610f', 'cc6a82']);

      expect(await transport.transceiveChained('00CA000000'), 'aabbcc6a82');
      expect(transport.commands, ['00CA000000', '00C0000000', '00C000000f']);
    },
  );

  test('does not continue a complete or rejected command', () async {
    for (final response in ['9000', 'abcd9000', '6982']) {
      final transport = _Transport([response]);
      expect(await transport.transceiveChained('00CA000000'), response);
      expect(transport.commands, ['00CA000000']);
    }
  });

  test('propagates transport failures during continuation', () async {
    final transport = _Transport(['aa6101']);
    await expectLater(
      transport.transceiveChained('00CA000000'),
      throwsStateError,
    );
    expect(transport.commands, ['00CA000000', '00C0000001']);
  });
}

class _Transport implements ApduTransport {
  _Transport(this.responses);
  final List<String> responses;
  final List<String> commands = [];

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    if (responses.isEmpty) throw StateError('Disconnected');
    return responses.removeAt(0);
  }
}
