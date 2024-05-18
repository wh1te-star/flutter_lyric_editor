import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class MusicPlayerService {
  final PublishSubject<dynamic> masterSubject;
  AudioPlayer player = AudioPlayer();
  late AssetSource audioFile;

  MusicPlayerService({required this.masterSubject}) {
    player.onPositionChanged.listen((event) {
      masterSubject.add(NotifySeekPosition(event.inMilliseconds));
    });
    player.onPlayerStateChanged.listen((event) {
      if (player.state == PlayerState.playing) {
        masterSubject.add(NotifyIsPlaying(true));
      } else {
        masterSubject.add(NotifyIsPlaying(false));
      }
    });
    masterSubject.stream.listen((signal) {
      if (signal is RequestPlayPause) {
        if (player.state == PlayerState.playing) {
          player.pause();
        } else {
          player.resume();
        }
      }
    });
  }

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
