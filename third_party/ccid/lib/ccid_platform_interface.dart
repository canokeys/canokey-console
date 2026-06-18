import 'package:platform_detector/platform_detector.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ccid.dart';
import 'ccid_method_channel.dart';
import 'ccid_pcsc.dart';

abstract class CcidPlatform extends PlatformInterface {
  /// Constructs a CcidPlatform.
  CcidPlatform() : super(token: _token);

  static final Object _token = Object();

  static final CcidPlatform _methodChannelInstance = MethodChannelCcid();

  static final CcidPlatform _pcscInstance = PcscCcid();

  /// The default instance of [CcidPlatform] to use.
  ///
  /// Defaults to [MethodChannelCcid].
  static CcidPlatform get instance {
    if (isMobile() || isMacOs()) {
      return _methodChannelInstance;
    } else {
      return _pcscInstance;
    }
  }

  Future<List<String>> listReaders() {
    throw UnimplementedError('poll() has not been implemented.');
  }

  Future<String?> transceive(String reader, String capdu) {
    throw UnimplementedError('transceive() has not been implemented.');
  }

  Future<CcidCard> connect(String reader) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> disconnect(String reader) {
    throw UnimplementedError('disconnect() has not been implemented.');
  }
}
