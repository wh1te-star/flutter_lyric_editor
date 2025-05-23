import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class WordCursor extends TextPaneCursor {
  SegmentRange segmentRange;
  bool isExpandMode = false;

  WordCursor({
    required LyricSnippet lyricSnippet,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.isExpandMode,
  }) : super(lyricSnippet, seekPosition);

  WordCursor._privateConstructor(
    super.lyricSnippet,
    super.seekPosition,
    this.segmentRange,
    this.isExpandMode,
  );
  static final WordCursor _empty = WordCursor._privateConstructor(
    LyricSnippet.empty,
    SeekPosition.empty,
    SegmentRange.empty,
    false,
  );
  static WordCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  WordCursor defaultCursor() {
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return WordCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(segmentIndex, segmentIndex),
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    SegmentRange nextSegmentRange = segmentRange.copyWith();

    if (!isExpandMode) {
      SentenceSegmentIndex currentIndex = segmentRange.startIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < SentenceSegmentIndex(0)) {
        return this;
      }
      nextSegmentRange.startIndex = nextIndex;

      nextSegmentRange.endIndex = segmentRange.endIndex - 1;
    } else {
      SentenceSegmentIndex currentIndex = segmentRange.endIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < segmentRange.startIndex) {
        return this;
      }
      nextSegmentRange.startIndex = segmentRange.startIndex;
      nextSegmentRange.endIndex = nextIndex;
    }

    return WordCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveRightCursor() {
    SegmentRange nextSegmentRange = segmentRange.copyWith();

    SentenceSegmentIndex currentIndex = segmentRange.endIndex;
    SentenceSegmentIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= lyricSnippet.sentenceSegments.length) {
      return this;
    }

    nextSegmentRange.endIndex = nextIndex;
    if (!isExpandMode) {
      nextSegmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return WordCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isExpandMode: isExpandMode,
    );
  }

  TextPaneCursor exitWordMode() {
    return BaseCursor.defaultCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToExpandMode() {
    bool isExpandMode = !this.isExpandMode;
    return copyWith(isExpandMode: isExpandMode);
  }

  @override
  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(rangeList.length, null);

    int startRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.startIndex);
    });
    int endRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.endIndex);
    });

    int shiftLength = 0;
    for (int index = 0; index <= endRangeIndex; index++) {
      SentenceSegmentIndex startIndex = rangeList[index].startIndex - shiftLength;
      SentenceSegmentIndex endIndex = rangeList[index].endIndex - shiftLength;
      if (index == startRangeIndex) {
        startIndex = cursor.segmentRange.startIndex - shiftLength;
      }
      if (index == endRangeIndex) {
        endIndex = cursor.segmentRange.endIndex - shiftLength;
      }

      if (startRangeIndex <= index && index <= endRangeIndex) {
        separatedCursors[index] = cursor.copyWith(
          segmentRange: SegmentRange(startIndex, endIndex),
        );
      }
      shiftLength += rangeList[index].length;
    }

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    WordCursor initialCursor = WordCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
      isExpandMode: isExpandMode,
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SentenceSegmentIndex segmentIndex = SentenceSegmentIndex(index);
      if (cursor.segmentRange.isInRange(segmentIndex)) {
        separatedCursors[index] = initialCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  WordCursor shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    SentenceSegmentIndex startIndex = segmentRange.startIndex - sentenceSegmentList.segmentLength;
    SentenceSegmentIndex endIndex = segmentRange.endIndex - sentenceSegmentList.segmentLength;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  @override
  WordCursor shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    SentenceSegmentIndex startIndex = segmentRange.startIndex - 1;
    SentenceSegmentIndex endIndex = segmentRange.endIndex - 1;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  WordCursor copyWith({
    LyricSnippet? lyricSnippet,
    SeekPosition? seekPosition,
    SegmentRange? segmentRange,
    bool? isExpandMode,
  }) {
    return WordCursor(
      lyricSnippet: lyricSnippet ?? this.lyricSnippet,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? this.segmentRange,
      isExpandMode: isExpandMode ?? this.isExpandMode,
    );
  }

  @override
  String toString() {
    return 'WordCursor(ID: $lyricSnippet, segmentIndex: $segmentRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final WordCursor otherSentenceSegments = other as WordCursor;
    if (lyricSnippet != otherSentenceSegments.lyricSnippet) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    if (isExpandMode != otherSentenceSegments.isExpandMode) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippet.hashCode ^ seekPosition.hashCode ^ segmentRange.hashCode ^ isExpandMode.hashCode;
}
