import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final musicPlayerMasterProvider = ChangeNotifierProvider((ref) => MusicPlayerService());

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  int _seekPosition = 0;
  bool _isPlaying = false;
  int _audioDuration = 0;
  late UriAudioSource audioFile;

  MusicPlayerService() {
    /*
    player.positionStream.listen((event) {
      _seekPosition = event.inMilliseconds;
      notifyListeners();
    });

    player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    player.durationStream.listen((duration) {
      if (duration != null) {
        _audioDuration = duration.inMilliseconds;
        notifyListeners();
      }
    });
    */
  }

  int get seekPosition => _seekPosition;
  bool get isPlaying => _isPlaying;
  int get audioDuration => _audioDuration;

  void playPause() {
    /*
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
    notifyListeners();
    */
  }

  Future<void> seek(int seekPosition) async {
    /*
    Duration position = Duration(milliseconds: seekPosition);
    await player.seek(position);
    _seekPosition = seekPosition;
    notifyListeners();
    */
  }

  Future<void> rewind(int millisec) async {
    /*
    var currentPosition = await player.position;
    if (currentPosition != null) {
      Duration newPosition = currentPosition - Duration(milliseconds: millisec);
      if (newPosition.inMilliseconds < 0) {
        newPosition = Duration.zero;
      }
      await player.seek(newPosition);
      _seekPosition = newPosition.inMilliseconds;
      notifyListeners();
    }
    */
  }

  Future<void> forward(int millisec) async {
    /*
    var currentPosition = await player.position;
    var musicDuration = await player.duration;
    if (currentPosition != null && musicDuration != null) {
      Duration newPosition = currentPosition + Duration(milliseconds: millisec);
      if (newPosition.inMilliseconds > musicDuration.inMilliseconds) {
        newPosition = musicDuration;
      }
      await player.seek(newPosition);
      _seekPosition = newPosition.inMilliseconds;
      notifyListeners();
    }
    */
  }

  void volumeUp(double value) {
    player.setVolume(player.volume + value);
  }

  void volumeDown(double value) {
    player.setVolume(player.volume - value);
  }

  void speedUp(double rate) {
    player.setSpeed(player.speed + rate);
  }

  void speedDown(double rate) {
    player.setSpeed(player.speed - rate);
  }

  void initAudio(String audioPath) {
    audioFile = AudioSource.uri(Uri.file(audioPath));
    player.setAudioSource(audioFile);
  }

  void play() {
    player.play();
  }

  void setVolume(double volume) {
    player.setVolume(volume);
  }
}
