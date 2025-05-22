import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class SegmentSelectionCursor extends TextPaneCursor {
  PhrasePosition segmentRange;
  bool isRangeSelection = false;

  SegmentSelectionCursor({
    required Sentence lyricSnippet,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.isRangeSelection,
  }) : super(lyricSnippet, seekPosition);

  SegmentSelectionCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.segmentRange,
    this.isRangeSelection,
  );
  static final SegmentSelectionCursor _empty = SegmentSelectionCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    PhrasePosition.empty,
    false,
  );
  static SegmentSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  SegmentSelectionCursor defaultCursor() {
    WordIndex segmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    return SegmentSelectionCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
      segmentRange: PhrasePosition(segmentIndex, segmentIndex),
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    PhrasePosition nextSegmentRange = segmentRange.copyWith();

    if (!isRangeSelection) {
      WordIndex currentIndex = segmentRange.startIndex;
      WordIndex nextIndex = currentIndex - 1;
      if (nextIndex < WordIndex(0)) {
        return this;
      }
      nextSegmentRange.startIndex = nextIndex;

      nextSegmentRange.endIndex = segmentRange.endIndex - 1;
    } else {
      WordIndex currentIndex = segmentRange.endIndex;
      WordIndex nextIndex = currentIndex - 1;
      if (nextIndex < segmentRange.startIndex) {
        return this;
      }
      nextSegmentRange.startIndex = segmentRange.startIndex;
      nextSegmentRange.endIndex = nextIndex;
    }

    return SegmentSelectionCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor moveRightCursor() {
    PhrasePosition nextSegmentRange = segmentRange.copyWith();

    WordIndex currentIndex = segmentRange.endIndex;
    WordIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= sentence.sentenceSegments.length) {
      return this;
    }

    nextSegmentRange.endIndex = nextIndex;
    if (!isRangeSelection) {
      nextSegmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return SegmentSelectionCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  TextPaneCursor exitWordSelectionMode() {
    return SentenceSelectionCursor.defaultCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToRangeSelection() {
    bool isRangeSelection = !this.isRangeSelection;
    return copyWith(isRangeSelection: isRangeSelection);
  }

  @override
  List<TextPaneCursor?> getPhraseDividedCursors(Sentence lyricSnippet, List<PhrasePosition> rangeList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);

    int startRangeIndex = rangeList.indexWhere((PhrasePosition segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.startIndex);
    });
    int endRangeIndex = rangeList.indexWhere((PhrasePosition segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.endIndex);
    });

    int shiftLength = 0;
    for (int index = 0; index <= endRangeIndex; index++) {
      WordIndex startIndex = rangeList[index].startIndex - shiftLength;
      WordIndex endIndex = rangeList[index].endIndex - shiftLength;
      if (index == startRangeIndex) {
        startIndex = cursor.segmentRange.startIndex - shiftLength;
      }
      if (index == endRangeIndex) {
        endIndex = cursor.segmentRange.endIndex - shiftLength;
      }

      if (startRangeIndex <= index && index <= endRangeIndex) {
        separatedCursors[index] = cursor.copyWith(
          segmentRange: PhrasePosition(startIndex, endIndex),
        );
      }
      shiftLength += rangeList[index].length;
    }

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList sentenceSegmentList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    SegmentSelectionCursor initialCursor = SegmentSelectionCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
      segmentRange: PhrasePosition(WordIndex(0), WordIndex(0)),
      isRangeSelection: isRangeSelection,
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      WordIndex segmentIndex = WordIndex(index);
      if (cursor.segmentRange.isInRange(segmentIndex)) {
        separatedCursors[index] = initialCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegmentList(WordList sentenceSegmentList) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    WordIndex startIndex = segmentRange.startIndex - sentenceSegmentList.segmentLength;
    WordIndex endIndex = segmentRange.endIndex - sentenceSegmentList.segmentLength;
    PhrasePosition newRange = PhrasePosition(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegment(Word sentenceSegment) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    WordIndex startIndex = segmentRange.startIndex - 1;
    WordIndex endIndex = segmentRange.endIndex - 1;
    PhrasePosition newRange = PhrasePosition(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  SegmentSelectionCursor copyWith({
    Sentence? lyricSnippet,
    SeekPosition? seekPosition,
    PhrasePosition? segmentRange,
    bool? isRangeSelection,
  }) {
    return SegmentSelectionCursor(
      lyricSnippet: lyricSnippet ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? this.segmentRange,
      isRangeSelection: isRangeSelection ?? this.isRangeSelection,
    );
  }

  @override
  String toString() {
    return 'SegmentSelectionCursor(ID: $sentence, segmentIndex: $segmentRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SegmentSelectionCursor otherSentenceSegments = other as SegmentSelectionCursor;
    if (sentence != otherSentenceSegments.sentence) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    if (isRangeSelection != otherSentenceSegments.isRangeSelection) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ segmentRange.hashCode ^ isRangeSelection.hashCode;
}
