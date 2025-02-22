import 'dart:async';
import 'dart:ui';

class CursorBlinker {
  int blinkIntervalInMillisec;
  bool isCursorVisible = true;
  late Timer cursorTimer;
  late VoidCallback onTick;

  static CursorBlinker get empty => CursorBlinker();
  bool get isEmpty => this == empty;

  CursorBlinker({this.blinkIntervalInMillisec = 1000, required this.onTick}) {
    cursorTimer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      isCursorVisible = !isCursorVisible;
      onTick();
    });
  }

  void pauseCursorTimer() {
    cursorTimer.cancel();
  }

  void restartCursorTimer() {
    cursorTimer.cancel();
    isCursorVisible = true;
    cursorTimer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      isCursorVisible = !isCursorVisible;
      onTick();
    });
  }

  SentenceSegment copyWith({String? word, Duration? duration}) {
    return SentenceSegment(
      word ?? this.word,
      duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'SentenceSegment(wordLength: $word, wordDuration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSegment otherSentenceSegments = other as SentenceSegment;
    return word == otherSentenceSegments.word && duration == otherSentenceSegments.duration;
  }

  @override
  int get hashCode => word.hashCode ^ duration.hashCode;
}
