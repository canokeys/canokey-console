import 'package:audioplayers/audioplayers.dart';

class Audio {
  static final AudioPlayer _player = AudioPlayer();

  static void poll() {
    _player.play(AssetSource('audio/poll.aac'), mode: PlayerMode.lowLatency);
  }

  static void finish() {
    _player.play(AssetSource('audio/finish.aac'), mode: PlayerMode.lowLatency);
  }

  static void error() {
    _player.play(AssetSource('audio/error.aac'), mode: PlayerMode.lowLatency);
  }
}
