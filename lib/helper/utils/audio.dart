import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

class Audio {

  static const int AUDIO_SET_NUM = 3;
  static final _poll = <Source>[];
  static final _finish = <Source>[];
  static final _error = <Source>[];
  static late int _current; // -1 for disabled

  static final _player = AudioPlayer();
  static final _playQueue = <Source>[];

  static final Logger log = Logging.logger('Audio');

  static void reloadSoundSet() {
    int sound = LocalStorage.getNfcSound() ?? 1;
    assert(sound >= -1 && sound < AUDIO_SET_NUM, 'Invalid audio set: $sound');
    _current = sound;
  }

  static void init() async {
    reloadSoundSet();
    AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build());
    // load all audio files
    for (var i = 1; i <= AUDIO_SET_NUM; i++) {
      _poll.add(AssetSource('audio/poll$i.aac'));
      _finish.add(AssetSource('audio/finish$i.aac'));
      _error.add(AssetSource('audio/error$i.aac'));
    }
    _player.setReleaseMode(ReleaseMode.stop);
    // support playing multiple sounds in a row
    _player.onPlayerStateChanged.listen((state) {
      log.i('Player state changed: $state');
      if (state == PlayerState.completed && _playQueue.isNotEmpty) {
        _playQueue.removeAt(0);
        if (_playQueue.isNotEmpty) {
          // sleep for 0.5 seconds before playing the next sound
          Future.delayed(const Duration(milliseconds: 500), () {
            _player.play(_playQueue.first, mode: PlayerMode.lowLatency);
          });
        }
      }
    });
  }

  static void playAll(int set) {
    if (set < 0) return;
    assert(set >= 0 && set < AUDIO_SET_NUM, 'Invalid audio set: $set');
    _player.stop().then((value) {
      _playQueue.clear();
      _playQueue.addAll([
        _poll[set],
        _finish[set],
        _error[set],
      ]);
      _player.play(_playQueue.first, mode: PlayerMode.lowLatency);
    });
  }

  static void poll() {
    if (_current < 0) return;
    _player.stop().then((value) => _player.play(_poll[_current]));
  }

  static void finish() {
    if (_current < 0) return;
    _player.stop().then((value) => _player.play(_finish[_current]));
  }

  static void error() {
    if (_current < 0) return;
    _player.stop().then((value) => _player.play(_error[_current]));
  }
}
