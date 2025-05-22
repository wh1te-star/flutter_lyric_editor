import 'dart:typed_data';

import 'package:lyric_editor/position/segment_index.dart';

class SegmentRange {
  SentenceSegmentIndex startIndex;
  SentenceSegmentIndex endIndex;
  SegmentRange(this.startIndex, this.endIndex) {
    if (!isEmpty) {
      assert(startIndex >= SentenceSegmentIndex(0));
      assert(endIndex >= SentenceSegmentIndex(0));
    }
  }

  SegmentRange._privateConstructor(this.startIndex, this.endIndex);
  static final SegmentRange _empty = SegmentRange._privateConstructor(SentenceSegmentIndex.empty, SentenceSegmentIndex.empty);
  static SegmentRange get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  int get length => endIndex.index - startIndex.index + 1;

  bool isInRange(SentenceSegmentIndex segmentIndex) {
    return startIndex <= segmentIndex && segmentIndex <= endIndex;
  }

  SegmentRange copyWith({SentenceSegmentIndex? startIndex, SentenceSegmentIndex? endIndex}) {
    return SegmentRange(
      startIndex ?? this.startIndex,
      endIndex ?? this.endIndex,
    );
  }

  @override
  String toString() {
    return "$startIndex<=>$endIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SegmentRange) {
      return false;
    }
    return startIndex == other.startIndex && endIndex == other.endIndex;
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
}
