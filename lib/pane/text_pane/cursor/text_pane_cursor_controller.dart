import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  TextPaneCursorMover textPaneCursorMover;

  TextPaneCursorController({
    required this.textPaneCursorMover,
  });

  TextPaneCursorController moveUpCursor() {
    return TextPaneCursorController(
      textPaneCursorMover: textPaneCursorMover.moveUpCursor(),
    );
  }

  TextPaneCursorController moveDownCursor() {
    return TextPaneCursorController(
      textPaneCursorMover: textPaneCursorMover.moveDownCursor(),
    );
  }

  TextPaneCursorController moveLeftCursor() {
    return TextPaneCursorController(
      textPaneCursorMover: textPaneCursorMover.moveLeftCursor(),
    );
  }

  TextPaneCursorController moveRightCursor() {
    return TextPaneCursorController(
      textPaneCursorMover: textPaneCursorMover.moveRightCursor(),
    );
  }

  TextPaneCursorController updateControllerBySeekPosition(
    LyricSnippetMap lyricSnippetsAtSeekPosition,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  ) {
    return TextPaneCursorController(
      textPaneCursorMover: updateMoverBySeekPosition(
        lyricSnippetsAtSeekPosition,
        cursorBlinker,
        seekPosition,
      ),
    );
  }

  TextPaneCursorMover updateMoverBySeekPosition(LyricSnippetMap lyricSnippetsAtSeekPosition, CursorBlinker cursorBlinker, SeekPosition seekPosition) {
    cursorBlinker.restartCursorTimer();

    if (lyricSnippetsAtSeekPosition.isEmpty) {
      return SentenceSelectionCursorMover(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        textPaneCursor: SentenceSelectionCursor.empty,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    TextPaneCursor textPaneCursor = textPaneCursorMover.textPaneCursor;

    LyricSnippetID lyricSnippetID = lyricSnippetsAtSeekPosition.keys.first;
    LyricSnippet lyricSnippet = lyricSnippetsAtSeekPosition.values.first;
    if (lyricSnippetsAtSeekPosition.containsKey(lyricSnippetID)) {
      lyricSnippetID = textPaneCursor.lyricSnippetID;
      lyricSnippet = lyricSnippetsAtSeekPosition[lyricSnippetID]!;
    }

    int currentSnippetPosition = lyricSnippet.timing.getSegmentIndexFromSeekPosition(seekPosition);
    PositionTypeInfo nextSnippetPosition = lyricSnippet.timing.getPositionTypeInfo((textPaneCursor as SentenceSelectionCursor).charPosition.position);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      return SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    return textPaneCursorMover;
  }

  TextPaneCursorController updateCursorByItemDeletion(LyricSnippetMap allLyricSnippetMap, LyricSnippetMap lyricSnippetsAtSeekPosition, CursorBlinker cursorBlinker, SeekPosition seekPosition) {
    if (lyricSnippetsAtSeekPosition.isEmpty) {
      return textPaneCursorMover;
    }

    TextPaneCursor textPaneCursor = textPaneCursorMover.textPaneCursor;
    LyricSnippet? lyricSnippet = allLyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      return SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: LyricSnippetID(1),
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    if (textPaneCursorMover is AnnotationSelectionCursorMover) {
      return textPaneCursorMover;
    }

    Annotation? annotation = lyricSnippet.annotationMap.map[(textPaneCursor as AnnotationSelectionCursor).segmentRange];
    if (annotation == null) {
      return AnnotationSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: textPaneCursor.lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }
    return textPaneCursorMover;
  }

  TextPaneCursorController copyWith({
    TextPaneCursorMover? textPaneCursorMover,
  }) {
    return TextPaneCursorController(
      textPaneCursorMover: textPaneCursorMover ?? this.textPaneCursorMover,
    );
  }

  @override
  String toString() {
    return 'TextPaneCursorController($textPaneCursorMover)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TextPaneCursorController otherTextPaneCursorController = other as TextPaneCursorController;
    if (textPaneCursorMover != otherTextPaneCursorController.textPaneCursorMover) return false;
    return true;
  }

  @override
  int get hashCode => textPaneCursorMover.hashCode;
}
