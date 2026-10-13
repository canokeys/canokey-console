import 'package:canokey_console/helper/utils/smartcard.dart';

abstract interface class ApduTransport {
  Future<String> transceive(String capdu);
}

class SmartCardApduTransport implements ApduTransport {
  const SmartCardApduTransport();

  @override
  Future<String> transceive(String capdu) => SmartCard.transceive(capdu);
}
