import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';

class WordInsertionPositionInfo implements InsertionPositionInfo {
  WordIndex wordIndex;
  WordInsertionPositionInfo(this.wordIndex);

  WordInsertionPositionInfo._privateConstructor(this.wordIndex);
  static final WordInsertionPositionInfo _empty = WordInsertionPositionInfo._privateConstructor(WordIndex.empty);
  static WordInsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  WordInsertionPositionInfo copyWith({
    WordIndex? index,
  }) {
    return WordInsertionPositionInfo(
      index ?? this.wordIndex,
    );
  }

  @override
  String toString() {
    return "InsertionPositionInfo: Word at index $wordIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WordInsertionPositionInfo) {
      return false;
    }
    return wordIndex == other.wordIndex;
  }

  @override
  int get hashCode => wordIndex.hashCode;
}
