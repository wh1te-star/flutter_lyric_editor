import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  late DeviceFileSource audioFile;
  BuildContext context;

  bool _isPlaying = false;
  int _seekPosition = 0;
  int _audioDuration = 240000;

  bool get isPlaying => _isPlaying;
  int get audioDuration => _audioDuration;
  int get seekPosition => _seekPosition;

  MusicPlayerService({required this.context}) {
    /*
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
      notifyListeners();
    });
    */
    player.onPlayerStateChanged.listen((event) {
      if (player.state == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      notifyListeners();
    });
    player.onPositionChanged.listen((event) {
      _seekPosition = event.inMilliseconds;
      notifyListeners();
    });
    player.onDurationChanged.listen((duration) {
      _audioDuration = duration.inMilliseconds;
      notifyListeners();
    });
  }

  void requestInitAudio() async {
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

  void requestPlayPause() {
    playPause();
  }

  void requestSeek(int seekPosition) {
    seek(seekPosition);
  }

  void requestRewind(int millisec) {
    rewind(millisec);
  }

  void requestForward(int millisec) {
    forward(millisec);
  }

  void requestVolumeUp(double value) {
    volumeUp(value);
  }

  void requestVolumeDown(double value) {
    volumeDown(value);
  }

  void requestSpeedUp(double rate) {
    speedUp(rate);
  }

  void requestSpeedDown(double rate) {
    speedDown(rate);
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
