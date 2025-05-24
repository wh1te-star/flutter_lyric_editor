import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';

class InvalidSeekPositionInfo implements SeekPositionInfo {
  SentenceSide sentenceSide;
  InvalidSeekPositionInfo(this.sentenceSide);

  InvalidSeekPositionInfo copyWith({
    SentenceSide? sentenceSide,
  }) {
    return InvalidSeekPositionInfo(
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
    if (other is! InvalidSeekPositionInfo) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
