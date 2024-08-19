import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  late DeviceFileSource audioFile;

  MusicPlayerService() {
    player.onPositionChanged.listen((event) {
      notifyListeners();
    });
    player.onPlayerStateChanged.listen((event) {
      notifyListeners();
    });
    player.onDurationChanged.listen((duration) {
      notifyListeners();
    });
  }

  get isPlaying {
    return player.state == PlayerState.playing;
  }

  get seekPosition {
    return player.getCurrentPosition();
  }

  get audioDuration async {
    return await player.getDuration();
  }

  void playPause() {
    if (player.state == PlayerState.playing) {
      player.pause();
    } else {
      player.resume();
    }
  }

  void seek(int seekPosition) async {
    Duration position = Duration(milliseconds: seekPosition);
    await player.seek(position);
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

  void volumeUp(double value) {
    player.setVolume(player.volume + value);
  }

  void volumeDown(double value) {
    player.setVolume(player.volume - value);
  }

  void speedUp(double rate) {
    player.setPlaybackRate(player.playbackRate + rate);
  }

  void speedDown(double rate) {
    player.setPlaybackRate(player.playbackRate - rate);
  }

  void initAudio(String audioPath) {
    audioFile = DeviceFileSource(audioPath);
    player.setSourceDeviceFile(audioPath);
  }

  void play() {
    player.play(audioFile);
  }

  void setVolume(double volume) {
    player.setVolume(volume);
  }
}
