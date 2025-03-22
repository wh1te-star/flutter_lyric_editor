import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class AnnotationSelectionCursor extends TextPaneCursor {
  SegmentRange segmentRange;
  InsertionPosition charPosition;
  Option option;

  AnnotationSelectionCursor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.segmentRange,
    this.charPosition,
    this.option,
  );

  AnnotationSelectionCursor._privateConstructor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.segmentRange,
    this.charPosition,
    this.option,
  );
  static final AnnotationSelectionCursor _empty = AnnotationSelectionCursor._privateConstructor(
    LyricSnippetID.empty,
    CursorBlinker.empty,
    SegmentRange.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static AnnotationSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  AnnotationSelectionCursor? shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    return this;
  }

  @override
  AnnotationSelectionCursor? shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    return this;
  }

  AnnotationSelectionCursor copyWith({
    LyricSnippetID? lyricSnippetID,
    CursorBlinker? cursorBlinker,
    SegmentRange? segmentRange,
    InsertionPosition? charPosition,
    Option? option,
  }) {
    return AnnotationSelectionCursor(
      lyricSnippetID ?? this.lyricSnippetID,
      cursorBlinker ?? this.cursorBlinker,
      segmentRange ?? this.segmentRange,
      charPosition ?? this.charPosition,
      option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'AnnotationSelectionCursor(ID: ${lyricSnippetID.id}, position: ${charPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final AnnotationSelectionCursor otherSentenceSegments = other as AnnotationSelectionCursor;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (cursorBlinker != otherSentenceSegments.cursorBlinker) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    if (charPosition != otherSentenceSegments.charPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetID.hashCode ^ cursorBlinker.hashCode ^ segmentRange.hashCode ^ charPosition.hashCode ^ option.hashCode;
}
