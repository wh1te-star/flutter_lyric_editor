class SentenceTrack implements Comparable<SentenceTrack> {
  int track;

  SentenceTrack(this.track) {
    if (!isEmpty) {
      assert(track >= 0);
    }
  }

  static final SentenceTrack _empty = SentenceTrack._privateConstructor(-1);
  static SentenceTrack get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  SentenceTrack._privateConstructor(this.track);

  SentenceTrack copyWith({int? track}) {
    return SentenceTrack(
      track ?? this.track,
    );
  }

  @override
  String toString() {
    return "SentenceTrack: $track";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SentenceTrack) {
      return false;
    }
    return track == other.track;
  }

  @override
  int get hashCode => track.hashCode;

  SentenceTrack operator +(int shift) => SentenceTrack(track + shift);
  SentenceTrack operator -(int shift) => SentenceTrack(track - shift);

  @override
  int compareTo(SentenceTrack other) {
    return track.compareTo(other.track);
  }

  bool operator >(SentenceTrack other) => track > other.track;
  bool operator <(SentenceTrack other) => track < other.track;
  bool operator >=(SentenceTrack other) => track >= other.track;
  bool operator <=(SentenceTrack other) => track <= other.track;
}
