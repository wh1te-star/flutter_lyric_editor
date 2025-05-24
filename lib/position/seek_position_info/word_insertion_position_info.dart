import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';

class WordSeekPositionInfo implements SeekPositionInfo {
  WordIndex wordIndex;
  WordSeekPositionInfo(this.wordIndex);

  WordSeekPositionInfo copyWith({
    WordIndex? wordIndex,
  }) {
    return WordSeekPositionInfo(
      wordIndex ?? this.wordIndex,
    );
  }

  @override
  String toString() {
    return "SeekPositionInfo: Word at index $wordIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WordSeekPositionInfo) {
      return false;
    }
    return wordIndex == other.wordIndex;
  }

  @override
  int get hashCode => wordIndex.hashCode;
}
