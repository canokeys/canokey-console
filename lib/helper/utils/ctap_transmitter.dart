import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:fido2/fido2.dart';
import 'package:convert/convert.dart';

class CtapTransmitter extends CtapDevice {
  CtapTransmitter({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  final ApduTransport _transport;

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    final lc = command.length <= 255
        ? [command.length]
        : [0, command.length >> 8, command.length & 0xff];
    var capdu = '80100000${hex.encode(lc)}${hex.encode(command)}';
    var rapdu = '';
    do {
      if (rapdu.length >= 4) {
        final remaining = rapdu.substring(rapdu.length - 2);
        capdu = '80C00000$remaining';
        rapdu = rapdu.substring(0, rapdu.length - 4);
      }
      rapdu += await _transport.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    final response = hex.decode(rapdu);
    return CtapResponse(response[0], response.sublist(1, response.length - 2));
  }
}
