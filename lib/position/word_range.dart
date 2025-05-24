import 'dart:typed_data';

import 'package:lyric_editor/position/word_index.dart';

class WordRange {
  WordIndex startIndex;
  WordIndex endIndex;
  WordRange(this.startIndex, this.endIndex) {
    if (!isEmpty) {
      assert(startIndex >= WordIndex(0));
      assert(endIndex >= WordIndex(0));
    }
  }

  WordRange._privateConstructor(this.startIndex, this.endIndex);
  static final WordRange _empty = WordRange._privateConstructor(WordIndex.empty, WordIndex.empty);
  static WordRange get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  int get length => endIndex.index - startIndex.index + 1;

  bool isInRange(WordIndex wordIndex) {
    return startIndex <= wordIndex && wordIndex <= endIndex;
  }

  WordRange copyWith({WordIndex? startIndex, WordIndex? endIndex}) {
    return WordRange(
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
    if (other is! WordRange) {
      return false;
    }
    return startIndex == other.startIndex && endIndex == other.endIndex;
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
}
