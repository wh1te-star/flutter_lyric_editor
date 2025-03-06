import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  TextPaneCursorMover textPaneCursorMover;

  bool isAnnotationSelection = false;
  bool isSegmentSelection = false;

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

  void updateCursorBySeekPosition() {
    LyricSnippetMap lyricSnippetsAtSeekPosition = timingService.getSnippetsAtSeekPosition();
    if (lyricSnippetsAtSeekPosition.isEmpty) {
      textPaneCursorMover = SentenceSelectionCursorMover(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        textPaneCursor: SentenceSelectionCursor.empty,
        cursorBlinker: cursorBlinker,
        seekPosition: musicPlayerProvider.seekPosition,
      );
      return;
    }

    SeekPosition seekPosition = musicPlayerProvider.seekPosition;
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
      textPaneCursorMover = SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    LyricSnippetMap lyricSnippetsAtSeekPosition = timingService.getSnippetsAtSeekPosition();
    if (lyricSnippetsAtSeekPosition.isEmpty) {
      return;
    }

    SeekPosition seekPosition = musicPlayerProvider.seekPosition;
    TextPaneCursor textPaneCursor = textPaneCursorMover.textPaneCursor;
    LyricSnippet? lyricSnippet = timingService.lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      textPaneCursorMover = SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: LyricSnippetID(1),
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      return;
    }

    if (isAnnotationSelection) {
      return;
    }

    Annotation? annotation = lyricSnippet.annotationMap.map[(textPaneCursor as AnnotationSelectionCursor).segmentRange];
    if (annotation == null) {
      textPaneCursorMover = AnnotationSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: textPaneCursor.lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      return;
    }
  }


  TextPaneCursorController copyWith({
    LyricSnippetMap? lyricSnippetMap,
    SentenceSelectionCursor? sentenceSelectionCursor,
    CursorBlinker? cursorBlinker,
    SeekPosition? seekPosition,
  }) {
    return TextPaneCursorController(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      textPaneCursor: sentenceSelectionCursor ?? textPaneCursor,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
      seekPosition: seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'TextPaneCursorController($lyricSnippetMap, $textPaneCursor, $cursorBlinker, $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TextPaneCursorController otherTextPaneCursorController = other as TextPaneCursorController;
    if (lyricSnippetMap != otherTextPaneCursorController.lyricSnippetMap) return false;
    if (textPaneCursor != otherTextPaneCursorController.textPaneCursor) return false;
    if (cursorBlinker != otherTextPaneCursorController.cursorBlinker) return false;
    if (seekPosition != otherTextPaneCursorController.seekPosition) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ textPaneCursor.hashCode ^ cursorBlinker.hashCode ^ seekPosition.hashCode;
}
