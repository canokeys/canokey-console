import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ccid.dart';
import 'ccid_platform_interface.dart';

/// An implementation of [CcidPlatform] that uses method channels.
class MethodChannelCcid extends CcidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ccid');

  @override
  Future<List<String>> listReaders() async {
    final result = await methodChannel.invokeListMethod<String>('listReaders');
    return result ?? [];
  }

  @override
  Future<CcidCard> connect(String reader) {
    return methodChannel
        .invokeMethod('connect', reader)
        .then((value) => CcidCard(reader));
  }

  @override
  Future<String?> transceive(String reader, String capdu) async {
    final result = await methodChannel
        .invokeMethod<String>('transceive', <String, dynamic>{
      'reader': reader,
      'capdu': capdu,
    });
    return result;
  }

  @override
  Future<void> disconnect(String reader) {
    return methodChannel.invokeMethod('disconnect', reader);
  }
}
