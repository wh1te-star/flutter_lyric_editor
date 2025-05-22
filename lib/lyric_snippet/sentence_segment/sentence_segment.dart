class SentenceSegment {
  String word;
  Duration duration;

  SentenceSegment(this.word, this.duration);

  SentenceSegment._privateConstructor(this.word, this.duration);
  static final SentenceSegment _empty = SentenceSegment._privateConstructor("", Duration.zero);
  static SentenceSegment get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

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
