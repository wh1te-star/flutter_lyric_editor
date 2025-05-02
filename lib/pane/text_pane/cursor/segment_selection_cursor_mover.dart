import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SegmentSelectionCursorMover extends TextPaneCursorMover {

  SegmentSelectionCursorMover copyWith({
    LyricSnippetMap? lyricSnippetMap,
    SegmentSelectionCursor? segmentSelectionCursor,
    CursorBlinker? cursorBlinker,
    SeekPosition? seekPosition,
    bool? isRangeSelection,
  }) {
    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      textPaneCursor: segmentSelectionCursor ?? textPaneCursor,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
      seekPosition: seekPosition ?? this.seekPosition,
      isRangeSelection: isRangeSelection ?? this.isRangeSelection,
    );
  }

  @override
  String toString() {
    return 'SegmentSelectionCursorMover($lyricSnippetMap, $textPaneCursor, $cursorBlinker, $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SegmentSelectionCursorMover otherSegmentSelectionCursorMover = other as SegmentSelectionCursorMover;
    if (lyricSnippetMap != otherSegmentSelectionCursorMover.lyricSnippetMap) return false;
    if (textPaneCursor != otherSegmentSelectionCursorMover.textPaneCursor) return false;
    if (cursorBlinker != otherSegmentSelectionCursorMover.cursorBlinker) return false;
    if (seekPosition != otherSegmentSelectionCursorMover.seekPosition) return false;
    if (isRangeSelection != otherSegmentSelectionCursorMover.isRangeSelection) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ textPaneCursor.hashCode ^ cursorBlinker.hashCode ^ seekPosition.hashCode ^ isRangeSelection.hashCode;
}
