import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SegmentSelectionCursorMover extends TextPaneCursorMover {
  bool isRangeSelection;
  SegmentSelectionCursorMover({
    required super.lyricSnippetMap,
    required super.textPaneCursor,
    required super.cursorBlinker,
    required super.seekPosition,
    required this.isRangeSelection,
  }) {
    assert(textPaneCursor is SegmentSelectionCursor, "Wrong type textPaneCursor is passed: SegmentSelectionCursor is expected but ${textPaneCursor.runtimeType} is passed.");
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
  }

  bool isIDContained() {
    if (textPaneCursor.isEmpty) {
      return true;
    }
    LyricSnippet? lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  factory SegmentSelectionCursorMover.withDefaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required CursorBlinker cursorBlinker,
    required SeekPosition seekPosition,
    required bool isRangeSelection,
  }) {
    final SegmentSelectionCursor tempCursor = SegmentSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      SegmentRange.empty,
    );
    final SegmentSelectionCursorMover tempMover = SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: tempCursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
    return tempMover.copyWith(segmentSelectionCursor: tempMover.defaultCursor(lyricSnippetID));
  }

  @override
  SegmentSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return SegmentSelectionCursor(textPaneCursor.lyricSnippetID, cursorBlinker, SegmentRange(segmentIndex, segmentIndex));
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
    return SegmentSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index + 1 >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    return SegmentSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveLeftCursor() {
    SegmentSelectionCursor cursor = textPaneCursor as SegmentSelectionCursor;
    SegmentRange segmentRange = cursor.segmentRange;

    if (!isRangeSelection) {
      SegmentIndex currentIndex = segmentRange.startIndex;
      SegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < SegmentIndex(0)) {
        return this;
      }
      segmentRange.startIndex = nextIndex;

      segmentRange.endIndex = segmentRange.endIndex - 1;
    } else {
      SegmentIndex currentIndex = segmentRange.endIndex;
      SegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < segmentRange.startIndex) {
        return this;
      }
      segmentRange.endIndex = nextIndex;
    }

    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveRightCursor() {
    SegmentSelectionCursor cursor = textPaneCursor as SegmentSelectionCursor;
    SegmentRange segmentRange = cursor.segmentRange;

    SegmentIndex currentIndex = segmentRange.endIndex;
    SegmentIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= lyricSnippetMap[cursor.lyricSnippetID]!.sentenceSegments.length) {
      return this;
    }
    segmentRange.endIndex = nextIndex;
    if (!isRangeSelection) {
      segmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  ) {
    cursorBlinker.restartCursorTimer();
    return this;
  }

  TextPaneCursorMover exitSegmentSelectionMode() {
    return SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: textPaneCursor.lyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursorMover switchToRangeSelection() {
    bool isRangeSelection = !this.isRangeSelection;
    return copyWith(isRangeSelection: isRangeSelection);
  }

  List<TextPaneCursor> getSegmentDividedCursors(LyricSnippet lyricSnippet, SentenceSegmentList sentenceSegmentList){
    List<SegmentSelectionCursor> separatedCursors = List.filled(sentenceSegmentList.length, SegmentSelectionCursor.empty);
    return separatedCursors;
  }

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
