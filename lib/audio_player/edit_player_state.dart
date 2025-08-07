import 'package:just_audio/just_audio.dart';

class EditPlayerState {
  final ProcessingState processingState;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? currentAudioUrl;

  const EditPlayerState({
    required this.processingState,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.currentAudioUrl,
  });

  EditPlayerState copyWith({
    ProcessingState? processingState,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? currentAudioUrl,
  }) {
    return EditPlayerState(
      processingState: processingState ?? this.processingState,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentAudioUrl: currentAudioUrl ?? this.currentAudioUrl,
    );
  }

  factory EditPlayerState.initial() => const EditPlayerState(
        processingState: ProcessingState.idle,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
}