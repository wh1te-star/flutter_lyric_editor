class ShowHideTrack implements Comparable<ShowHideTrack> {
  int track;

  ShowHideTrack(this.track) {
    if (!isEmpty) {
      assert(track >= 0);
    }
  }

  static final ShowHideTrack _empty = ShowHideTrack._privateConstructor(-1);
  static ShowHideTrack get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  ShowHideTrack._privateConstructor(this.track);

  ShowHideTrack copyWith({int? track}) {
    return ShowHideTrack(
      track ?? this.track,
    );
  }

  @override
  String toString() {
    return "ShowHideTrack: $track";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ShowHideTrack) {
      return false;
    }
    return track == other.track;
  }

  @override
  int get hashCode => track.hashCode;

  ShowHideTrack operator +(int shift) => ShowHideTrack(track + shift);
  ShowHideTrack operator -(int shift) => ShowHideTrack(track - shift);

  @override
  int compareTo(ShowHideTrack other) {
    return track.compareTo(other.track);
  }

  bool operator >(ShowHideTrack other) => track > other.track;
  bool operator <(ShowHideTrack other) => track < other.track;
  bool operator >=(ShowHideTrack other) => track >= other.track;
  bool operator <=(ShowHideTrack other) => track <= other.track;
}