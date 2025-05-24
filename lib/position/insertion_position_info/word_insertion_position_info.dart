import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';

class WordInsertionPositionInfo implements InsertionPositionInfo {
  WordIndex wordIndex;
  WordInsertionPositionInfo(this.wordIndex);

  WordInsertionPositionInfo copyWith({
    WordIndex? wordIndex,
  }) {
    return WordInsertionPositionInfo(
      wordIndex ?? this.wordIndex,
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
