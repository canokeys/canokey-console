@Tags(['native'])
library;

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/ctap_transmitter.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('selects once, frames CTAP commands and follows GET RESPONSE', () async {
    final transport = _QueueApduTransport(['9000', '006102', 'A19000']);
    final transmitter = CtapTransmitter(transport: transport);

    final response = await transmitter.transceive([0x04]);

    expect(response.status, 0);
    expect(response.data, [0xA1]);
    expect(transport.commands, [
      '00A4040008A0000006472F0001',
      '801000000104',
      '80C0000002',
    ]);
  });

  test('reuses the selection for subsequent messages', () async {
    final transport = _QueueApduTransport(['9000', '009000', '2E9000']);
    final transmitter = CtapTransmitter(transport: transport);

    await transmitter.transceive([0x04]);
    final response = await transmitter.transceive([0x0A]);

    // A non-success CTAP status byte is data, not an error.
    expect(response.status, 0x2E);
    expect(response.data, isEmpty);
    expect(transport.commands, [
      '00A4040008A0000006472F0001',
      '801000000104',
      '80100000010A',
    ]);
  });

  test('explicit reselection selects again', () async {
    final transport = _QueueApduTransport(['9000', '009000', '9000']);
    final transmitter = CtapTransmitter(transport: transport);

    await transmitter.transceive([0x04]);
    await transmitter.selectApplication();

    expect(transport.commands, [
      '00A4040008A0000006472F0001',
      '801000000104',
      '00A4040008A0000006472F0001',
    ]);
  });

  test('a new transmitter without lease evidence selects again', () async {
    // Without a lease there is no shared selection evidence, so a new
    // transmitter selects the applet before its first message.
    final transport = _QueueApduTransport(['9000', '009000']);
    final response = await CtapTransmitter(
      transport: transport,
    ).transceive([0x04]);
    expect(response.status, 0);
    expect(transport.commands, [
      '00A4040008A0000006472F0001',
      '801000000104',
    ]);
  });

  test('transmitters sharing a lease select the applet once', () async {
    final sessions = CardSessions();
    final transport = _QueueApduTransport(['9000', '009000', '009000']);
    await sessions.run((session) async {
      session.bind(transport.transceive);
      final first = CtapTransmitter(
        transport: transport,
        lease: session.lease,
      );
      await first.transceive([0x04]);
      // The selection belongs to the lease, so a second transmitter instance
      // reuses it instead of selecting again.
      final second = CtapTransmitter(
        transport: transport,
        lease: session.lease,
      );
      final response = await second.transceive([0x0A]);
      expect(response.status, 0);
    });
    expect(transport.commands, [
      '00A4040008A0000006472F0001',
      '801000000104',
      '80100000010A',
    ]);
  });

  test('an absent FIDO2 applet surfaces as UnsupportedDevice', () async {
    final transport = _QueueApduTransport(['6A82']);
    final transmitter = CtapTransmitter(transport: transport);

    await expectLater(
      transmitter.transceive([0x04]),
      throwsA(
        isA<ProtocolException>().having(
          (error) => error.details.kind,
          'kind',
          'UnsupportedDevice',
        ),
      ),
    );
    expect(transport.commands, ['00A4040008A0000006472F0001']);
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
