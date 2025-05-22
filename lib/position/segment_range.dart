import 'dart:typed_data';

import 'package:lyric_editor/position/segment_index.dart';

class Phrase {
  WordIndex startIndex;
  WordIndex endIndex;
  Phrase(this.startIndex, this.endIndex) {
    if (!isEmpty) {
      assert(startIndex >= WordIndex(0));
      assert(endIndex >= WordIndex(0));
    }
  }

  Phrase._privateConstructor(this.startIndex, this.endIndex);
  static final Phrase _empty = Phrase._privateConstructor(WordIndex.empty, WordIndex.empty);
  static Phrase get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  int get length => endIndex.index - startIndex.index + 1;

  bool isInRange(WordIndex segmentIndex) {
    return startIndex <= segmentIndex && segmentIndex <= endIndex;
  }

  Phrase copyWith({WordIndex? startIndex, WordIndex? endIndex}) {
    return Phrase(
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
    if (other is! Phrase) {
      return false;
    }
    return startIndex == other.startIndex && endIndex == other.endIndex;
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
}
