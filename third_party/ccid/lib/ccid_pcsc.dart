import 'dart:async';

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
  Future<void>? _initializing;
  Future<void> _operationTail = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _init() {
    if (_initialized) {
      return Future.value();
    }
    return _initializing ??= _establishContext();
  }

  Future<void> _establishContext() async {
    try {
      await context.establish();
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  @override
  Future<List<String>> listReaders() {
    return _serialize(() async {
      await _init();
      return context.listReaders();
    });
  }

  @override
  Future<CcidCard> connect(String reader) {
    return _serialize(() async {
      await _init();
      if (readerCardMap.containsKey(reader)) {
        throw StateError('Reader is already connected');
      }
      final card = await context.connect(
        reader,
        ShareMode.shared,
        Protocol.any,
      );
      readerCardMap[reader] = card;
      return CcidCard(reader);
    });
  }

  @override
  Future<String?> transceive(String reader, String capdu) {
    return _serialize(() async {
      final card = readerCardMap[reader];
      if (card == null) {
        throw StateError('Card not connected');
      }
      final apdu = Uint8List.fromList(hex.decode(capdu));
      final rapdu = await card.transmit(apdu);
      return hex.encode(rapdu);
    });
  }

  @override
  Future<void> disconnect(String reader) {
    return _serialize(() async {
      final card = readerCardMap.remove(reader);
      try {
        if (card != null) {
          await card.disconnect(Disposition.resetCard);
        }
      } finally {
        if (readerCardMap.isEmpty && _initialized) {
          try {
            await context.release();
          } finally {
            _initialized = false;
          }
        }
      }
    });
  }
}
