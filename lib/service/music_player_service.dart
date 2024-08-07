import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class MusicPlayerService {
  final PublishSubject<dynamic> masterSubject;
  AudioPlayer player = AudioPlayer();
  late DeviceFileSource audioFile;
  BuildContext context;

  MusicPlayerService({required this.context, required this.masterSubject}) {
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
    player.onDurationChanged.listen((duration) {
      masterSubject.add(NotifyAudioFileLoaded(duration.inMilliseconds));
    });
    masterSubject.stream.listen((signal) async {
      if (signal is RequestInitAudio) {
        final XTypeGroup typeGroup = XTypeGroup(
          label: 'audio',
          extensions: ['mp3', 'wav', 'flac'],
          mimeTypes: ['audio/mpeg', 'audio/x-wav', 'audio/flac'],
        );
        final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

        if (file != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Selected file: ${file.name}'),
          ));
          initAudio(file.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
        }
      }
      if (signal is RequestPlayPause) {
        playPause();
      }
      if (signal is RequestSeek) {
        seek(signal.seekPosition);
      }
      if (signal is RequestRewind) {
        rewind(signal.millisec);
      }
      if (signal is RequestForward) {
        forward(signal.millisec);
      }
      if (signal is RequestVolumeUp) {
        volumeUp(signal.value);
      }
      if (signal is RequestVolumeDown) {
        volumeDown(signal.value);
      }
      if (signal is RequestSpeedUp) {
        speedUp(signal.rate);
      }
      if (signal is RequestSpeedDown) {
        speedDown(signal.rate);
      }
    });
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
