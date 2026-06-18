import 'package:convert/convert.dart';
import 'package:dart_pcsc/dart_pcsc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ccid.dart';
import 'ccid_platform_interface.dart';

/// An implementation of [CcidPlatform] that uses dart_pcsc.
class PcscCcid extends CcidPlatform {
  final context = Context(Scope.user);
  final readerCardMap = <String, Card>{};
  var _initialized = false;

  _init() async {
    if (!_initialized) {
      _initialized = true;
      await context.establish();
    }
  }

  @override
  Future<List<String>> listReaders() async {
    await _init();
    return await context.listReaders();
  }

  @override
  Future<CcidCard> connect(String reader) async {
    final card = await context.connect(reader, ShareMode.shared, Protocol.any);
    readerCardMap[reader] = card;
    return CcidCard(reader);
  }

  @override
  Future<String?> transceive(String reader, String capdu) async {
    final card = readerCardMap[reader];
    if (card == null) {
      throw Exception('Card not connected');
    }
    final apdu = Uint8List.fromList(hex.decode(capdu));
    final rapdu = await card.transmit(apdu);
    return hex.encode(rapdu);
  }

  @override
  Future<void> disconnect(String reader) async {
    final card = readerCardMap.remove(reader);
    if (card != null) {
      await card
          .disconnect(Disposition.resetCard)
          .then((_) => context.release());
    }
    return Future.value();
  }
}
