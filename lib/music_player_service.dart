import 'package:audioplayers/audioplayers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:lyric_editor/media_control_interface.dart';
import 'package:flutter/foundation.dart';

class MusicPlayerService implements MediaControlInterface {
  final PublishSubject<dynamic> masterSubject;

  MusicPlayerService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {
      if (signal['type'] == 'play') {
        debugPrint('MusicService: Handling play signal');
        if (player.state == PlayerState.playing) {
          debugPrint("playing");
          player.pause();
        } else {
          debugPrint("stopping");
          player.resume();
        }
      }
    });
  }

  AudioPlayer player = AudioPlayer();
  late AssetSource audioFile;

  void initAudio(String audioPath) {
    audioFile = AssetSource(audioPath);
  }

  void play() {
    player.play(audioFile);
  }

  @override
  void onPlayPause() {
    debugPrint("Play/Pause button tapped in music_player_service.dart");
  }

  @override
  void onChangeColor() {}

  void setVolume(double volume) {
    player.setVolume(volume);
  }
}
