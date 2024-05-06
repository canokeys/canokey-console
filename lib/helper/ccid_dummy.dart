class Ccid {
  /// List available readers
  ///
  /// Returns a list of reader names
  Future<List<String>> listReaders() {
    return Future(() => []);
  }

  /// Connect to a reader by its name [reader]
  ///
  /// Returns a [CcidCard] object
  Future<CcidCard> connect(String reader) {
    return Future(() => CcidCard(""));
  }
}

class CcidCard {
  final String reader;

  CcidCard(this.reader);

  /// Send APDU command [cpadu]
  ///
  /// Returns the response APDU
  Future<String?> transceive(String capdu) {
    return Future(() => "");
  }

  /// Disconnect from the card
  Future<void> disconnect() {
    return Future(() => null);
  }
}
