class SentenceID {
  int id;
  SentenceID(this.id);

  static SentenceID get empty => SentenceID(0);

  bool get isEmpty => id == 0;

  SentenceID copyWith({int? id}) {
    return SentenceID(id ?? this.id);
  }

  @override
  String toString() => 'SentenceID($id)';

  @override
  bool operator ==(Object other) {
    if (other is SentenceID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;
}
