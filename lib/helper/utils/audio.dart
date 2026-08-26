import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:platform_detector/platform_detector.dart';

class Audio {
  static const int soundSetCount = 3;
  static const int defaultSoundSet = 0;
  static const MethodChannel _channel =
      MethodChannel('org.canokeys.console/audio');
  static int _current = defaultSoundSet; // -1 for disabled

  static final Logger log = Logging.logger('Audio');

  static void reloadSoundSet() {
    final sound = LocalStorage.getNfcSound() ?? defaultSoundSet;
    assert(sound >= -1 && sound < soundSetCount, 'Invalid audio set: $sound');
    _current = sound;
  }

  static void init() {
    if (!isAndroidApp()) return;
    reloadSoundSet();
  }

  static Future<void> playAll(int set) async {
    if (!isAndroidApp() || set < 0) return;
    assert(set >= 0 && set < soundSetCount, 'Invalid audio set: $set');
    await _stop();
    // there is no easy way to get notified when the sound is finished
    // so we just wait for 1 second and then play the next sound
    await _play('poll', set);
    await Future.delayed(const Duration(milliseconds: 1000));
    await _play('finish', set);
    await Future.delayed(const Duration(milliseconds: 1000));
    await _play('error', set);
  }

  static Future<void> poll() => _play('poll', _current);

  static Future<void> finish() => _play('finish', _current);

  static Future<void> error() => _play('error', _current);

  static Future<void> _play(String kind, int set) async {
    if (!isAndroidApp() || set < 0) return;
    try {
      await _channel.invokeMethod<void>('play', {'kind': kind, 'set': set});
    } on PlatformException catch (error, stackTrace) {
      log.w('Failed to play NFC interaction sound',
          error: error, stackTrace: stackTrace);
    }
  }

  static Future<void> _stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error, stackTrace) {
      log.w('Failed to stop NFC interaction sound',
          error: error, stackTrace: stackTrace);
    }
  }
}
