import 'package:lyric_editor/diff_function/diff_segment.dart';

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

    while (prefixLength < beforeStr.length && prefixLength < afterStr.length && beforeStr[prefixLength] == afterStr[prefixLength]) {
      prefixLength++;
    }

    while (suffixLength < (beforeStr.length - prefixLength) && suffixLength < (afterStr.length - prefixLength) && beforeStr[beforeStr.length - 1 - suffixLength] == afterStr[afterStr.length - 1 - suffixLength]) {
      suffixLength++;
    }

    if (prefixLength > 0) {
      segments.add(DiffSegment(
        beforeStr.substring(0, prefixLength),
        afterStr.substring(0, prefixLength),
      ));
    }

    String beforeMiddle = beforeStr.substring(prefixLength, beforeStr.length - suffixLength);
    String afterMiddle = afterStr.substring(prefixLength, afterStr.length - suffixLength);
    if (beforeMiddle.isNotEmpty || afterMiddle.isNotEmpty) {
      segments.add(DiffSegment(beforeMiddle, afterMiddle));
    }

    if (suffixLength > 0) {
      segments.add(DiffSegment(
        beforeStr.substring(beforeStr.length - suffixLength),
        afterStr.substring(afterStr.length - suffixLength),
      ));
    }
    return segments;
  }
}
