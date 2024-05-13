import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:lyric_editor/media_control_interface.dart';
import 'package:flutter/foundation.dart';

class MusicPlayerService implements MediaControlInterface {
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
    if (player.state == PlayerState.playing) {
      debugPrint("playing");
      player.pause();
    } else {
      debugPrint("stopping");
      player.resume();
    }
  }

  @override
  void onChangeColor() {}

  void setVolume(double volume) {
    player.setVolume(volume);
  }
}
