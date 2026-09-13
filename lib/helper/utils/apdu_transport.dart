import 'package:canokey_console/helper/utils/smartcard.dart';

abstract interface class ApduTransport {
  Future<String> transceive(String capdu);
}

class SmartCardApduTransport implements ApduTransport {
  const SmartCardApduTransport();

  @override
  Future<String> transceive(String capdu) => SmartCard.transceive(capdu);
}

/// ISO 7816 GET RESPONSE chaining. OATH uses applet-specific continuation
/// commands and deliberately keeps its own response loop.
extension ApduResponseChaining on ApduTransport {
  Future<String> transceiveChained(String command) async {
    final data = StringBuffer();
    while (true) {
      final response = await transceive(command);
      final status = response.substring(response.length - 4);
      data.write(SmartCard.dropSW(response));
      if (!status.startsWith('61')) return '$data$status';
      command = '00C00000${status.substring(2)}';
    }
  }
}
