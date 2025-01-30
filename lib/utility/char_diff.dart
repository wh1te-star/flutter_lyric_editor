class CharDiff {
  String beforeStr;
  String afterStr;
  List<DiffSegment> segments = [];
  CharDiff(this.beforeStr, this.afterStr) {
    segments = getDiffSegments(beforeStr, afterStr);
  }

  List<DiffSegment> getDiffSegments(String beforeStr, String afterStr) {
    List<DiffSegment> segments = [];
    int beforeIndex = 0, afterIndex = 0;
    while (beforeIndex < beforeStr.length || afterIndex < afterStr.length) {
      if (beforeIndex < beforeStr.length && afterIndex < afterStr.length && beforeStr[beforeIndex] == afterStr[afterIndex]) {
        // Find the length of the unchanged segment
        int start = beforeIndex;
        while (beforeIndex < beforeStr.length && afterIndex < afterStr.length && beforeStr[beforeIndex] == afterStr[afterIndex]) {
          beforeIndex++;
          afterIndex++;
        }
        segments.add(DiffSegment(beforeStr.substring(start, beforeIndex), afterStr.substring(start, afterIndex)));
      } else {
        // Handle edits, deletions, and additions
        int startBefore = beforeIndex;
        int startAfter = afterIndex;
        while (beforeIndex < beforeStr.length && (afterIndex >= afterStr.length || beforeStr[beforeIndex] != afterStr[afterIndex])) {
          beforeIndex++;
        }
        while (afterIndex < afterStr.length && (beforeIndex >= beforeStr.length || beforeStr[beforeIndex] != afterStr[afterIndex])) {
          afterIndex++;
        }
        segments.add(DiffSegment(
          beforeStr.substring(startBefore, beforeIndex),
          afterStr.substring(startAfter, afterIndex),
        ));
      }
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
