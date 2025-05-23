class WordDiff {
  final String beforeStr;
  final String afterStr;

  WordDiff(this.beforeStr, this.afterStr) {
    assert(beforeStr != "" || afterStr != "");
  }

  WordDiff copyWith({
    String? beforeStr,
    String? afterStr,
  }) {
    assert((beforeStr ?? beforeStr) != "" || (afterStr ?? afterStr) != "");
    return WordDiff(
      beforeStr ?? this.beforeStr,
      afterStr ?? this.afterStr,
    );
  }

  @override
  String toString() {
    return "$beforeStr -> $afterStr";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is WordDiff && runtimeType == other.runtimeType && beforeStr == other.beforeStr && afterStr == other.afterStr;

  @override
  int get hashCode => beforeStr.hashCode ^ afterStr.hashCode;
}
