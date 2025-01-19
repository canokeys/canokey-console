import 'package:audioplayers/audioplayers.dart';

class Audio {
  static late AudioPool _poll, _finish, _error;

  static void init() async {
    AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build());
    _poll = await AudioPool.createFromAsset(path: 'audio/poll.aac', maxPlayers: 1);
    _finish = await AudioPool.createFromAsset(path: 'audio/finish.aac', maxPlayers: 1);
    _error = await AudioPool.createFromAsset(path: 'audio/error.aac', maxPlayers: 1);
  }

  static void poll() {
    _poll.start();
  }

  static void finish() {
    _finish.start();
  }

  static void error() {
    _error.start();
  }
}
