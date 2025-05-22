import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';

class SentenceSegmentInsertionPositionInfo implements InsertionPositionInfo {
  WordIndex sentenceSegmentIndex;
  SentenceSegmentInsertionPositionInfo(this.sentenceSegmentIndex);

  SentenceSegmentInsertionPositionInfo._privateConstructor(this.sentenceSegmentIndex);
  static final SentenceSegmentInsertionPositionInfo _empty = SentenceSegmentInsertionPositionInfo._privateConstructor(WordIndex.empty);
  static SentenceSegmentInsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  SentenceSegmentInsertionPositionInfo copyWith({
    WordIndex? index,
  }) {
    return SentenceSegmentInsertionPositionInfo(
      index ?? this.sentenceSegmentIndex,
    );
  }

  @override
  String toString() {
    return "InsertionPositionInfo: SentenceSegment at index $sentenceSegmentIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SentenceSegmentInsertionPositionInfo) {
      return false;
    }
    return sentenceSegmentIndex == other.sentenceSegmentIndex;
  }

  @override
  int get hashCode => sentenceSegmentIndex.hashCode;
}
