import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final musicPlayerMasterProvider = ChangeNotifierProvider((ref) => MusicPlayerService());

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  int _seekPosition = 0;
  bool _isPlaying = false;
  int _audioDuration = 0;
  late DeviceFileSource audioFile;

  MusicPlayerService() {
    player.onPositionChanged.listen((event) {
      _seekPosition = event.inMilliseconds;
      notifyListeners();
    });
    player.onPlayerStateChanged.listen((event) {
      if (player.state == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      notifyListeners();
    });
    player.onDurationChanged.listen((duration) {
      _audioDuration = duration.inMilliseconds;
      notifyListeners();
    });
  }

  int get seekPosition => _seekPosition;

  bool get isPlaying => _isPlaying;

  int get audioDuration => _audioDuration;

  void playPause() {
    if (player.state == PlayerState.playing) {
      player.pause();
    } else {
      player.resume();
    }
    notifyListeners();
  }

  int roundToNear(int number, int unit) {
    return ((number / unit).round()) * unit;
  }

  void seek(int seekPosition) async {
    int roundedSeekPosition = roundToNear(seekPosition, 100);
    Duration position = Duration(milliseconds: roundedSeekPosition);
    player.seek(position);
    _seekPosition = roundedSeekPosition;
    notifyListeners();
  }

  void rewind(int millisec) async {
    var currentPosition = await player.getCurrentPosition();
    if (currentPosition != null) {
      Duration newPosition = currentPosition - Duration(milliseconds: millisec);
      if (newPosition.inMilliseconds < 0) {
        newPosition = Duration.zero;
      }
      player.seek(newPosition);
      _seekPosition = newPosition.inMilliseconds;
      notifyListeners();
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
      _seekPosition = newPosition.inMilliseconds;
      notifyListeners();
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
