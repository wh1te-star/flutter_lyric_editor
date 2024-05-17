import 'package:audioplayers/audioplayers.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

class MusicPlayerService {
  final PublishSubject<dynamic> masterSubject;

  MusicPlayerService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {
      if (signal is RequestGetIsPlaying) {
        if (player.state == PlayerState.playing) {
          masterSubject.add(RespondGetIsPlaying(true));
        } else {
          masterSubject.add(RespondGetIsPlaying(false));
        }
      }
      if (signal is RequestPlayPause) {
        if (player.state == PlayerState.playing) {
          player.pause();
        } else {
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

  void setVolume(double volume) {
    player.setVolume(volume);
  }
}
