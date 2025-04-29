class LyricSnippetTrack implements Comparable<LyricSnippetTrack> {
  int track;

  LyricSnippetTrack(this.track) {
    if (!isEmpty) {
      assert(track >= 0);
    }
  }

  static final LyricSnippetTrack _empty = LyricSnippetTrack._privateConstructor(-1);
  static LyricSnippetTrack get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  LyricSnippetTrack._privateConstructor(this.track);

  LyricSnippetTrack copyWith({int? track}) {
    return LyricSnippetTrack(
      track ?? this.track,
    );
  }

  @override
  String toString() {
    return "LyricSnippetTrack: $track";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LyricSnippetTrack) {
      return false;
    }
    return track == other.track;
  }

  @override
  int get hashCode => track.hashCode;

  LyricSnippetTrack operator +(int shift) => LyricSnippetTrack(track + shift);
  LyricSnippetTrack operator -(int shift) => LyricSnippetTrack(track - shift);

  @override
  int compareTo(LyricSnippetTrack other) {
    return track.compareTo(other.track);
  }

  bool operator >(LyricSnippetTrack other) => track > other.track;
  bool operator <(LyricSnippetTrack other) => track < other.track;
  bool operator >=(LyricSnippetTrack other) => track >= other.track;
  bool operator <=(LyricSnippetTrack other) => track <= other.track;
}
