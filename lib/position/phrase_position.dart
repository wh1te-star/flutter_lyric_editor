import 'dart:typed_data';

import 'package:lyric_editor/position/word_index.dart';

class PhrasePosition {
  WordIndex startIndex;
  WordIndex endIndex;
  PhrasePosition(this.startIndex, this.endIndex) {
    if (!isEmpty) {
      assert(startIndex >= WordIndex(0));
      assert(endIndex >= WordIndex(0));
    }
  }

  PhrasePosition._privateConstructor(this.startIndex, this.endIndex);
  static final PhrasePosition _empty = PhrasePosition._privateConstructor(WordIndex.empty, WordIndex.empty);
  static PhrasePosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  int get length => endIndex.index - startIndex.index + 1;

  bool isInRange(WordIndex segmentIndex) {
    return startIndex <= segmentIndex && segmentIndex <= endIndex;
  }

  PhrasePosition copyWith({WordIndex? startIndex, WordIndex? endIndex}) {
    return PhrasePosition(
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
    if (other is! PhrasePosition) {
      return false;
    }
    return startIndex == other.startIndex && endIndex == other.endIndex;
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
}
