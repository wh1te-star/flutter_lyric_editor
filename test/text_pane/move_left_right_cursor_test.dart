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
import 'package:lyric_editor/pane/text_pane/cursor/mover/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/segment_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

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

    bool sentenceSelectionCursorMatcher(SentenceSelectionCursorMover result, SentenceSelectionCursor expectedCursor) {
      if (result.textPaneCursor is! SentenceSelectionCursor) return false;

      SentenceSelectionCursor resultCursor = result.textPaneCursor as SentenceSelectionCursor;
      return resultCursor == expectedCursor;
    }

    bool cursorMatcher(TextPaneCursorMover result, TextPaneCursor expectedCursor) {
      if (result is SentenceSelectionCursorMover) {
        assert(expectedCursor is SentenceSelectionCursor, "The result type and the expected type are not match, the expected cursor can be incorrect.");
        sentenceSelectionCursorMatcher(result, expectedCursor as SentenceSelectionCursor);
      }
      if (result is AnnotationSelectionCursorMover) {
        assert(expectedCursor is AnnotationSelectionCursor, "The result type and the expected type are not match, the expected cursor can be incorrect.");
        //annotationSelectionCursorMatcher(result, expectedCursor as AnnotationSelectionCursor);
      }
      if (result is SegmentSelectionCursorMover) {
        assert(expectedCursor is SegmentSelectionCursor, "The result type and the expected type are not match, the expected cursor can be incorrect.");
        //segmentSelectionCursorMatcher(result, expectedCursor as SegmentSelectionCursorMover);
      }
      assert(false, "An unexpected state is occurred for the text pane cursor type, the cursor is not any of those.");
      return false;
    }

    bool cursorMovementMatcher(TextPaneCursorMover initialMover, List<dynamic> expectedMovement) {
      TextPaneCursorMover result;
      for (List<dynamic> position in expectedMovement) {
        result = initialMover.moveRightCursor();
        bool matcherResult = cursorMatcher(result, expectedCursor);
        if (matcherResult == false) return false;
      }
      return true;
    }

    setUp(() {});
    test('Test to add a timing point No.1', () {
      SentenceSelectionCursorMover target = mover.copyWith();

      List<Tuple2<int, Option>> expectedCursorMovement = [
        const Tuple2(2, Option.former),
      ];

      expect(cursorMovementMatcher(target, expectedCursorMovement), true);
    });
  });
}
