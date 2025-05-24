import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class WordSeekPositionInfo implements SeekPositionInfo {
  SentenceSide sentenceSide;
  WordSeekPositionInfo(this.sentenceSide);

  WordSeekPositionInfo copyWith({
    SentenceSide? sentenceSide,
  }) {
    return WordSeekPositionInfo(
      sentenceSide ?? this.sentenceSide,
    );
  }

  @override
  String toString() {
    return "InvalidSeekPositionInfo(${sentenceSide.name})";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WordSeekPositionInfo) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
