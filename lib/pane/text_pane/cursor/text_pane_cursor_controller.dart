import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  final LyricSnippetMap lyricSnippetMap;
  final LyricSnippetID lyricSnippetID;
  final TextPaneCursor textPaneCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorController({
    required this.lyricSnippetMap,
    required this.lyricSnippetID,
    required this.textPaneCursor,
    required this.seekPosition,
    required this.cursorBlinker,
  });

  TextPaneCursorController._privateConstructor(
    this.lyricSnippetMap,
    this.lyricSnippetID,
    this.textPaneCursor,
    this.seekPosition,
    this.cursorBlinker,
  );
  static final TextPaneCursorController _empty = TextPaneCursorController._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SentenceSelectionCursor.empty,
    SeekPosition.empty,
    CursorBlinker.empty,
  );
  static TextPaneCursorController get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TextPaneCursorController moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveUpCursor();
    return copyWith(textPaneCursor: nextCursor);
  }

  TextPaneCursorController moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveDownCursor();
    return copyWith(textPaneCursor: nextCursor);
  }

  TextPaneCursorController moveLeftCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveLeftCursor();
    return copyWith(textPaneCursor: nextCursor);
  }

  TextPaneCursorController moveRightCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveRightCursor();
    return copyWith(textPaneCursor: nextCursor);
  }

  TextPaneCursorController enterSegmentSelectionMode() {
    assert(textPaneCursor is SentenceSelectionCursor, "This is an unexpected call. The cursor type must be SentenceSelectionCursor, but is ${textPaneCursor.runtimeType}");
    TextPaneCursor cursor = (textPaneCursor as SentenceSelectionCursor).enterSegmentSelectionMode();
    return copyWith(textPaneCursor: cursor);
  }

  TextPaneCursorController exitSegmentSelectionMode() {
    assert(textPaneCursor is SegmentSelectionCursor, "This is an unexpected call. The cursor type must be SegmentSelectionCursor, but is ${textPaneCursor.runtimeType}");
    TextPaneCursor cursor = (textPaneCursor as SegmentSelectionCursor).exitSegmentSelectionMode();
    return copyWith(textPaneCursor: cursor);
  }

  TextPaneCursorController switchToRangeSelection() {
    assert(textPaneCursor is SegmentSelectionCursor, "This is an unexpected call. The cursor type must be SegmentSelectionCursor, but is ${textPaneCursor.runtimeType}");
    TextPaneCursor cursor = (textPaneCursor as SegmentSelectionCursor).switchToRangeSelection();
    return copyWith(textPaneCursor: cursor);
  }

  TextPaneCursorController updateCursor(
    LyricSnippetMap lyricSnippetMap,
    SeekPosition seekPosition,
  ) {
    TextPaneCursor nextCursor = textPaneCursor.updateCursor(lyricSnippetMap, lyricSnippetID, seekPosition);
    return copyWith(textPaneCursor: nextCursor);
  }

  TextPaneCursorController copyWith({
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    TextPaneCursor? textPaneCursor,
    SeekPosition? seekPosition,
    CursorBlinker? cursorBlinker,
  }) {
    return TextPaneCursorController(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      textPaneCursor: textPaneCursor ?? this.textPaneCursor,
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
    if (textPaneCursor != otherSentenceSegments.textPaneCursor) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (cursorBlinker != otherSentenceSegments.cursorBlinker) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ textPaneCursor.hashCode ^ seekPosition.hashCode ^ cursorBlinker.hashCode;
}
