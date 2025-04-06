import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

abstract class TextPaneCursorMover {
  final LyricSnippetMap lyricSnippetMap;
  final TextPaneCursor textPaneCursor;
  final CursorBlinker cursorBlinker;
  final SeekPosition seekPosition;

  TextPaneCursorMover({
    required this.lyricSnippetMap,
    required this.textPaneCursor,
    required this.cursorBlinker,
    required this.seekPosition,
  });

  TextPaneCursor defaultCursor(LyricSnippetID lyricSnippetID);
  TextPaneCursorMover moveUpCursor();
  TextPaneCursorMover moveDownCursor();
  TextPaneCursorMover moveLeftCursor();
  TextPaneCursorMover moveRightCursor();
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  );
  List<TextPaneCursor> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList);
  List<TextPaneCursor> getSegmentDividedCursors(LyricSnippet lyricSnippet, SentenceSegmentList sentenceSegmentList);
}

/*
TextPaneCursorMover moveUpCursor() {
  if (isSegmentSelection) {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    LyricSnippet lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID];
    assert(lyricSnippet != null);

    int? annotationIndex = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);

    if (isAnnotationSelection || annotationIndex == null) {
      int index = currentSnippets.keys.toList().indexWhere((id) => id == textPaneCursor.lyricSnippetID);
      if (index > 0) {
        LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index - 1];
        textPaneCursor = getDefaultSentenceSelectionCursor(nextSnippetID);
      }
    } else {
      textPaneCursor = getDefaultAnnotationSelectionCursor(textPaneCursor.lyricSnippetID);
    }
  }

  TextPaneCursorMover moveDownCursor() {
    if (isSegmentSelection) {
      if (isAnnotationSelection) {
        textPaneCursor = getDefaultSentenceSelectionCursor(textPaneCursor.lyricSnippetID);
      } else {
        Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;

        int index = currentSnippets.keys.toList().indexWhere((id) => id == textPaneCursor.lyricSnippetID);
        if (index != -1 && index + 1 < currentSnippets.length) {
          LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index + 1];
          LyricSnippet nextSnippet = currentSnippets.values.toList()[index + 1];

          int? annotationIndex = nextSnippet.getAnnotationRangeFromSeekPosition(musicPlayerProvider.seekPosition);
          if (annotationIndex == null) {
            textPaneCursor = getDefaultSentenceSelectionCursor(nextSnippetID);
          } else {
            textPaneCursor = getDefaultAnnotationSelectionCursor(nextSnippetID);
          }
        }
      }
    }

    debugPrint("$textPaneCursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  TextPaneCursorMover moveLeftCursor() {
    if (!timingService.lyricSnippetMap.containsKey(textPaneCursor.lyricSnippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[textPaneCursor.lyricSnippetID]!;

    if (isSegmentSelection) {
      Timing object = isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = object.getPositionTypeInfo(textPaneCursor.charPosition.position);
      int seekPositionInfo = object.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.latter) {
        cursor.option = Option.former;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
        if (cursor.charPosition.position - 1 > 0) {
          cursor.charPosition--;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      } else {
        if (object.timingPoints[charPositionIndex - 1].charPosition.position > 0) {
          cursor.charPosition = object.timingPoints[charPositionIndex - 1].charPosition;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex - 1;
        if (nextSegmentIndex >= 0) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex - 1;
        if (nextSegmentIndex >= cursor.annotationSegmentRange.startIndex) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  TextPaneCursorMover moveRightCursor() {
    if (!timingService.lyricSnippetMap.containsKey(cursor.lyricSnippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[cursor.lyricSnippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      Timing timing = !cursor.isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = timing.getPositionTypeInfo(cursor.charPosition.position);
      int seekPositionInfo = timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.former) {
        cursor.option = Option.latter;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
        if (cursor.charPosition.position + 1 < timing.sentence.length) {
          cursor.charPosition++;
          cursor.option = Option.former;
        }
      } else {
        if (timing.timingPoints[charPositionIndex + 1].charPosition.position < timing.sentence.length) {
          cursor.charPosition = timing.timingPoints[charPositionIndex + 1].charPosition;
          cursor.option = Option.former;
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex + 1;
        if (nextSegmentIndex <= snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }
}
*/