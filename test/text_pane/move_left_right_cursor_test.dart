import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point_exception.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/text_pane/cursor/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/segment_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class PositionTestInfo {
  int charPosition;
  Option option;

  PositionTestInfo(this.charPosition, this.option);
}

void main() {
  group('Tests to move to left and right the text pane cursor.', () {
    final LyricSnippetID lyricSnippetID = LyricSnippetID(1);
    final Timing timingData = Timing(
      startTimestamp: SeekPosition(2000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]),
    );
    final LyricSnippet lyricSnippet = LyricSnippet(
      vocalistID: VocalistID(1),
      timing: timingData,
      annotationMap: AnnotationMap.empty,
    );

    final CursorBlinker cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {},
    );

    final SentenceSelectionCursor cursor = SentenceSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      InsertionPosition(1),
      Option.former,
    );

    final SentenceSelectionCursorMover mover = SentenceSelectionCursorMover(
      lyricSnippetMap: LyricSnippetMap({lyricSnippetID: lyricSnippet}),
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: SeekPosition(2200),
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    SentenceSelectionCursor constructCursor(PositionTestInfo positionInfo) {
      return SentenceSelectionCursor(
        lyricSnippetID,
        cursorBlinker,
        InsertionPosition(positionInfo.charPosition),
        positionInfo.option,
      );
    }

    bool cursorMatcher(SentenceSelectionCursorMover result, SentenceSelectionCursor expectedCursor) {
      if (result.textPaneCursor is! SentenceSelectionCursor) return false;

      SentenceSelectionCursor resultCursor = result.textPaneCursor as SentenceSelectionCursor;
      return resultCursor == expectedCursor;
    }

    bool cursorMovementMatcher(TextPaneCursorMover initialMover, List<PositionTestInfo> expectedMovement) {
      TextPaneCursorMover result = initialMover;
      for (int index = 0; index < expectedMovement.length; index++) {
        PositionTestInfo position = expectedMovement[index];
        SentenceSelectionCursor expectedCursor = constructCursor(position);

        result = result.moveRightCursor();
        assert(result is SentenceSelectionCursorMover, "An unexpected state was occurred.");

        bool matcherResult = cursorMatcher(result as SentenceSelectionCursorMover, expectedCursor);
        if (!matcherResult) {
          SentenceSelectionCursor resultCursor = result.textPaneCursor as SentenceSelectionCursor;
          debugPrint('Test failed at iteration ${index + 1}:');
          debugPrint('Expected cursor position: ${position.charPosition}, option: ${position.option}');
          debugPrint('But the actual cursor position: ${resultCursor.charPosition}, option: ${resultCursor.option}');
          return false;
        }
      }
      return true;
    }

// Usage
    setUp(() {});
    test('Test to move left and right the text pane cursor No.1', () {
      SentenceSelectionCursorMover target = mover.copyWith();

      List<PositionTestInfo> expectedCursorMovement = [
        PositionTestInfo(2, Option.former),
        PositionTestInfo(3, Option.former),
        PositionTestInfo(5, Option.former),
        PositionTestInfo(12, Option.former),
        PositionTestInfo(12, Option.latter),
        PositionTestInfo(17, Option.former),
        PositionTestInfo(19, Option.former),
      ];

      expect(cursorMovementMatcher(target, expectedCursorMovement), true);
    });
  });
}
