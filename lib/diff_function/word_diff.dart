class DiffSegment {
  final String beforeStr;
  final String afterStr;

  DiffSegment(this.beforeStr, this.afterStr) {
    assert(beforeStr != "" || afterStr != "");
  }

  DiffSegment copyWith({
    String? beforeStr,
    String? afterStr,
  }) {
    assert((beforeStr ?? beforeStr) != "" || (afterStr ?? afterStr) != "");
    return DiffSegment(
      beforeStr ?? this.beforeStr,
      afterStr ?? this.afterStr,
    );
  }

  @override
  String toString() {
    return "$beforeStr -> $afterStr";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DiffSegment && runtimeType == other.runtimeType && beforeStr == other.beforeStr && afterStr == other.afterStr;

  @override
  int get hashCode => beforeStr.hashCode ^ afterStr.hashCode;
}
