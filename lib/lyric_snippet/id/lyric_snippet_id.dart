class LyricSnippetID {
  int id;
  LyricSnippetID(this.id);

  static LyricSnippetID get empty {
    return LyricSnippetID(0);
  }

  bool isEmpty() {
    return id == 0;
  }

  LyricSnippetID copyWith({int? id}) {
    return LyricSnippetID(id ?? this.id);
  }

  @override
  String toString() => 'SnippetID($id)';

  @override
  bool operator ==(Object other) {
    if (other is LyricSnippetID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;
}
