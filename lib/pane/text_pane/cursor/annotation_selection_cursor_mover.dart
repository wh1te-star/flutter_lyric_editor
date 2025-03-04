import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class AnnotationSelectionCursorMover extends TextPaneCursorMover {
  AnnotationSelectionCursorMover({
    required super.lyricSnippetMap,
    required super.textPaneCursor,
    required super.cursorBlinker,
    required super.seekPosition,
  }) {
    assert(textPaneCursor is AnnotationSelectionCursor, "Wrong type textPaneCursor is passed: AnnotationSelectionCursor is expected but ${textPaneCursor.runtimeType} is passed.");
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
    assert(doesSeekPositionPointAnnotation(), "The passed seek position does not point to any annotation.");
  }

  bool isIDContained() {
    LyricSnippet? lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  bool doesSeekPositionPointAnnotation() {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(textPaneCursor.lyricSnippetID);
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    return annotationSegmentRange.isNotEmpty;
  }

  factory AnnotationSelectionCursorMover.withDefaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required CursorBlinker cursorBlinker,
    required SeekPosition seekPosition,
  }) {
    final AnnotationSelectionCursor tempCursor = AnnotationSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      SegmentRange.empty,
      InsertionPosition.empty,
      Option.former,
    );
    final AnnotationSelectionCursorMover tempMover = AnnotationSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: tempCursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
    return tempMover.copyWith(annotationSelectionCursor: tempMover.defaultCursor(lyricSnippetID));
  }

  @override
  AnnotationSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    Annotation annotation = lyricSnippet.annotationMap[annotationSegmentRange]!;
    int index = annotation.timing.getSegmentIndexFromSeekPosition(seekPosition);

    return AnnotationSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      annotationSegmentRange,
      annotation.timingPoints[index].charPosition + 1,
      Option.former,
    );
  }

  @override
  TextPaneCursorMover moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneCursorMover moveDownCursor() {
    return this;
  }

  @override
  TextPaneCursorMover moveLeftCursor() {
    return this;
  }

  @override
  TextPaneCursorMover moveRightCursor() {
    return this;
  }

  AnnotationSelectionCursorMover copyWith({
    LyricSnippetMap? lyricSnippetMap,
    AnnotationSelectionCursor? annotationSelectionCursor,
    CursorBlinker? cursorBlinker,
    SeekPosition? seekPosition,
  }) {
    return AnnotationSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      textPaneCursor: annotationSelectionCursor ?? textPaneCursor,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
      seekPosition: seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'AnnotationSelectionCursorMover($lyricSnippetMap, $textPaneCursor, $cursorBlinker, $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final AnnotationSelectionCursorMover otherAnnotationSelectionCursorMover = other as AnnotationSelectionCursorMover;
    if (lyricSnippetMap != otherAnnotationSelectionCursorMover.lyricSnippetMap) return false;
    if (textPaneCursor != otherAnnotationSelectionCursorMover.textPaneCursor) return false;
    if (cursorBlinker != otherAnnotationSelectionCursorMover.cursorBlinker) return false;
    if (seekPosition != otherAnnotationSelectionCursorMover.seekPosition) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ textPaneCursor.hashCode ^ cursorBlinker.hashCode ^ seekPosition.hashCode;
}
