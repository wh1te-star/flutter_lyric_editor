import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'edit_player_state.dart';

class PlayerNotifier extends StateNotifier<EditPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerNotifier() : super(EditPlayerState.initial()) {
    _audioPlayer.playerStateStream.listen((playerState) {
      state = state.copyWith(
        processingState: playerState.processingState,
        isPlaying: playerState.playing,
      );
    });

    _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  Future<void> playAudio(String audioUrl) async {
    await _audioPlayer.stop();
    await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
    state = state.copyWith(currentAudioUrl: audioUrl);
    await _audioPlayer.play();
  }

  Future<void> play() async => _audioPlayer.play();

  Future<void> pause() async => _audioPlayer.pause();

  Future<void> seek(Duration position) async => _audioPlayer.seek(position);

  Future<void> forward10Seconds() async {
    final newPosition = _audioPlayer.position + const Duration(seconds: 10);
    if (newPosition < (_audioPlayer.duration ?? newPosition)) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(_audioPlayer.duration);
    }
  }

  Future<void> rewind10Seconds() async {
    final newPosition = _audioPlayer.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}