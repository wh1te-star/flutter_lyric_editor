class SentenceSegment {
  String word;
  int duration;

  SentenceSegment(this.word, this.duration) {
    assert(duration >= 0);
  }

  static SentenceSegment get empty {
    return SentenceSegment("", 0);
  }

  bool isEmpty() {
    return word == "" && duration == 0;
  }

  SentenceSegment copyWith({String? word, int? duration}) {
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
