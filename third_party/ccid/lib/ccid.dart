import 'ccid_platform_interface.dart';

class Ccid {
  /// List available readers
  ///
  /// Returns a list of reader names
  Future<List<String>> listReaders() {
    return CcidPlatform.instance.listReaders();
  }

  /// Connect to a reader by its name [reader]
  ///
  /// Returns a [CcidCard] object
  Future<CcidCard> connect(String reader) {
    return CcidPlatform.instance.connect(reader);
  }
}

class CcidCard {
  final String reader;

  CcidCard(this.reader);

  /// Send APDU command [cpadu]
  ///
  /// Returns the response APDU
  Future<String?> transceive(String capdu) {
    return CcidPlatform.instance.transceive(reader, capdu);
  }

  /// Disconnect from the card
  Future<void> disconnect() {
    return CcidPlatform.instance.disconnect(reader);
  }
}
