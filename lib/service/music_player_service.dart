import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

final musicPlayerMasterProvider = ChangeNotifierProvider((ref) => MusicPlayerService());

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  AbsoluteSeekPosition _seekPosition = AbsoluteSeekPosition(10);
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  late DeviceFileSource audioFile;

  MusicPlayerService() {
    player.onPositionChanged.listen((Duration event) {
      _seekPosition = AbsoluteSeekPosition(event.inMilliseconds);
      notifyListeners();
    });
    player.onPlayerStateChanged.listen((PlayerState event) {
      if (player.state == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      notifyListeners();
    });
    player.onDurationChanged.listen((Duration duration) {
      _audioDuration = Duration(milliseconds: duration.inMilliseconds);
      notifyListeners();
    });
  }

  AbsoluteSeekPosition get seekPosition => _seekPosition;

  bool get isPlaying => _isPlaying;

  Duration get audioDuration => _audioDuration;

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

  void seek(int targetSeekPosition) async {
    Duration position = Duration(milliseconds: targetSeekPosition);
    player.seek(position);
    _seekPosition = AbsoluteSeekPosition(targetSeekPosition);
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
      _seekPosition = AbsoluteSeekPosition(newPosition.inMilliseconds);
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
      _seekPosition = AbsoluteSeekPosition(newPosition.inMilliseconds);
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
