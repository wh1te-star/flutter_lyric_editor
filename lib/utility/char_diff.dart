class CharDiff {
  String beforeStr;
  String afterStr;
  List<DiffSegment> segments = [];
  CharDiff(this.beforeStr, this.afterStr) {
    segments = getDiffSegments(beforeStr, afterStr);
  }

  List<DiffSegment> getDiffSegments(String beforeStr, String afterStr) {
    List<DiffSegment> segments = [];
    int prefixLength = 0;
    int suffixLength = 0;

    // Find common prefix
    while (prefixLength < beforeStr.length && prefixLength < afterStr.length && beforeStr[prefixLength] == afterStr[prefixLength]) {
      prefixLength++;
    }

    // Find common suffix
    while (suffixLength < (beforeStr.length - prefixLength) && suffixLength < (afterStr.length - prefixLength) && beforeStr[beforeStr.length - 1 - suffixLength] == afterStr[afterStr.length - 1 - suffixLength]) {
      suffixLength++;
    }

    // Add common prefix segment
    if (prefixLength > 0) {
      segments.add(DiffSegment(
        beforeStr.substring(0, prefixLength),
        afterStr.substring(0, prefixLength),
      ));
    }

    // Add differing middle segment
    String beforeMiddle = beforeStr.substring(prefixLength, beforeStr.length - suffixLength);
    String afterMiddle = afterStr.substring(prefixLength, afterStr.length - suffixLength);
    if (beforeMiddle.isNotEmpty || afterMiddle.isNotEmpty) {
      segments.add(DiffSegment(beforeMiddle, afterMiddle));
    }

    // Add common suffix segment
    if (suffixLength > 0) {
      segments.add(DiffSegment(
        beforeStr.substring(beforeStr.length - suffixLength),
        afterStr.substring(afterStr.length - suffixLength),
      ));
    }
    return segments;
  }
}

class DiffSegment {
  String beforeStr;
  String afterStr;
  DiffSegment(this.beforeStr, this.afterStr);

  @override
  String toString() {
    return "$beforeStr -> $afterStr";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DiffSegment && runtimeType == other.runtimeType && beforeStr == other.beforeStr && afterStr == other.afterStr;

  @override
  int get hashCode => beforeStr.hashCode ^ afterStr.hashCode;
}
