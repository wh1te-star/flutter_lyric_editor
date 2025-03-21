import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursor {
  LyricSnippetID lyricSnippetID;
  CursorBlinker cursorBlinker;
  TextPaneCursor(this.lyricSnippetID, this.cursorBlinker);

  TextPaneCursor._privateConstructor(
    this.lyricSnippetID,
    this.cursorBlinker,
  );
  static final TextPaneCursor _empty = TextPaneCursor._privateConstructor(
    LyricSnippetID.empty,
    CursorBlinker.empty,
  );
  static TextPaneCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TextPaneCursor shiftLeftBy(SentenceSegmentList sentenceSegmentList) {
    return this;
  }
}

/*
{
  void enterSegmentSelectionMode() {
    isSegmentSelectionMode = true;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  void exitSegmentSelectionMode() {
    isSegmentSelectionMode = false;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  bool isInRange(int index) {
    if (annotationSegmentRange.startIndex <= annotationSegmentRange.endIndex) {
      return annotationSegmentRange.startIndex <= index && index <= annotationSegmentRange.endIndex;
    } else {
      return annotationSegmentRange.endIndex <= index && index <= annotationSegmentRange.startIndex;
    }
  }

  TextPaneCursor copyWith({
    LyricSnippetID? snippetID,
    InsertionPosition? charPosition,
    Option? option,
    bool? isSegmentSelectionMode,
    bool? isRangeSelection,
    bool? isAnnotationSelection,
    SegmentRange? annotationSegmentRange,
  }) {
    return TextPaneCursor(
      snippetID ?? this.snippetID,
      charPosition ?? this.charPosition,
      option ?? this.option,
      isSegmentSelectionMode ?? this.isSegmentSelectionMode,
      isRangeSelection ?? this.isRangeSelection,
      isAnnotationSelection ?? this.isAnnotationSelection,
      annotationSegmentRange ?? this.annotationSegmentRange,
    );
  }

  @override
  String toString() {
    if (!isAnnotationSelection) {
      if (!isSegmentSelectionMode) {
        return "SnippetSelection-> snippetID: $snippetID, charPosition: $charPosition, option: $option";
      } else {
        return "SegmentSelection-> snippetID: $snippetID, segment range: $annotationSegmentRange";
      }
    } else {
      return "AnnotationSelection-> snippetID: $snippetID, annotationRange: $annotationSegmentRange, charPosition: $charPosition, option: $option";
    }
  }

  static TextPaneCursor get emptyValue {
    return TextPaneCursor(
      LyricSnippetID(0),
      InsertionPosition(0),
      Option.former,
      false,
      false,
      false,
      SegmentRange.empty,
    );
  }
}
*/