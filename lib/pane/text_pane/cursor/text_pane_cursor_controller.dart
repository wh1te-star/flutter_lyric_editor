import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/segment_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/sentence_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  final LyricSnippetMap lyricSnippetMap;
  final LyricSnippetID lyricSnippetID;
  final TextPaneListCursor textPaneListCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorController({
    required this.lyricSnippetMap,
    required this.lyricSnippetID,
    required this.textPaneListCursor,
    required this.seekPosition,
    required this.cursorBlinker,
  });

  TextPaneCursorController._privateConstructor(
    this.lyricSnippetMap,
    this.lyricSnippetID,
    this.textPaneListCursor,
    this.seekPosition,
    this.cursorBlinker,
  );
  static final TextPaneCursorController _empty = TextPaneCursorController._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SentenceSelectionListCursor.empty,
    SeekPosition.empty,
    CursorBlinker.empty,
  );
  static TextPaneCursorController get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TextPaneCursorController moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveUpCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveDownCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveLeftCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveLeftCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveRightCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveRightCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController enterSegmentSelectionMode() {
    assert(textPaneListCursor is SentenceSelectionCursor, "This is an unexpected call. The cursor type must be SentenceSelectionCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as SentenceSelectionListCursor).enterSegmentSelectionMode();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController exitSegmentSelectionMode() {
    assert(textPaneListCursor is SegmentSelectionCursor, "This is an unexpected call. The cursor type must be SegmentSelectionCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as SegmentSelectionListCursor).exitSegmentSelectionMode();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController switchToRangeSelection() {
    assert(textPaneListCursor is SegmentSelectionCursor, "This is an unexpected call. The cursor type must be SegmentSelectionCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as SegmentSelectionListCursor).switchToRangeSelection();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController updateCursor(
    LyricSnippetMap lyricSnippetMap,
    SeekPosition seekPosition,
  ) {
    TextPaneListCursor nextCursor = textPaneListCursor.updateCursor(lyricSnippetMap, lyricSnippetID, seekPosition);
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController copyWith({
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    TextPaneListCursor? textPaneListCursor,
    SeekPosition? seekPosition,
    CursorBlinker? cursorBlinker,
  }) {
    return TextPaneCursorController(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      textPaneListCursor: textPaneListCursor ?? this.textPaneListCursor,
      seekPosition: seekPosition ?? this.seekPosition,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
    );
  }

  @override
  String toString() {
    return 'TextPaneCursorController()';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TextPaneCursorController otherSentenceSegments = other as TextPaneCursorController;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (textPaneListCursor != otherSentenceSegments.textPaneListCursor) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (cursorBlinker != otherSentenceSegments.cursorBlinker) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ textPaneListCursor.hashCode ^ seekPosition.hashCode ^ cursorBlinker.hashCode;
}
