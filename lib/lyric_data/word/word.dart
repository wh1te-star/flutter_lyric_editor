class Word {
  String word;
  Duration duration;

  Word(this.word, this.duration);

  Word._privateConstructor(this.word, this.duration);
  static final Word _empty = Word._privateConstructor("", Duration.zero);
  static Word get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  Word copyWith({String? word, Duration? duration}) {
    return Word(
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
    final Word otherSentenceSegments = other as Word;
    return word == otherSentenceSegments.word && duration == otherSentenceSegments.duration;
  }

  @override
  int get hashCode => word.hashCode ^ duration.hashCode;
}
