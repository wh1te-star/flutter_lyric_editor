import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';

class WordCaretPositionInfo implements CaretPositionInfo {
  WordIndex wordIndex;
  WordCaretPositionInfo(this.wordIndex);

  WordCaretPositionInfo copyWith({
    WordIndex? wordIndex,
  }) {
    return WordCaretPositionInfo(
      wordIndex ?? this.wordIndex,
    );
  }

  @override
  String toString() {
    return "CaretPositionInfo: Word at index $wordIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WordCaretPositionInfo) {
      return false;
    }
    return wordIndex == other.wordIndex;
  }

  @override
  int get hashCode => wordIndex.hashCode;
}
