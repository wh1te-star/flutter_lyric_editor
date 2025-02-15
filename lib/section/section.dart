class Section {
  int seekPosition;

  Section(this.seekPosition);

  static Section get empty => Section(-1);
  bool get isEmpty => this == empty;

  Section copyWith({
    int? seekPosition,
  }) {
    return Section(seekPosition ?? this.seekPosition);
  }

  @override
  String toString() {
    return "Section($seekPosition)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Section) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return seekPosition == other.seekPosition;
  }

  @override
  int get hashCode => seekPosition.hashCode;
}
