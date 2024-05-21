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
      if (signal is RequestRewind) {
        rewind(signal.millisec);
      }
    });
  }

  void rewind(int millisec) async {
    var currentPosition = await player.getCurrentPosition();
    if (currentPosition != null) {
      Duration newPosition = currentPosition - Duration(milliseconds: millisec);
      if (newPosition.inMilliseconds < 0) {
        newPosition = Duration.zero;
      }
      player.seek(newPosition);
    }
  }

  void forward(int millisec) async {
    var currentPosition = await player.getCurrentPosition();
    var musicDuration = await player.getDuration();
    if (currentPosition != null && musicDuration != null) {
      Duration newPosition = currentPosition + Duration(milliseconds: millisec);
      if (newPosition.inMilliseconds > musicDuration.inMilliseconds) {
        newPosition = musicDuration;
      }
      player.seek(newPosition);
    }
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
