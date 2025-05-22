import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/text_pane/cursor/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/segment_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/reading_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
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
    final Timeline timingData1 = Timeline(
      startTime: SeekPosition(2000),
      wordList: WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]),
    );
    final Timeline timingData2 = Timeline(
      startTime: SeekPosition(2000),
      wordList: WordList([
        Word("abcde", const Duration(milliseconds: 1000)),
        Word("", const Duration(milliseconds: 1000)),
        Word("fghij", const Duration(milliseconds: 1000)),
        Word("", const Duration(milliseconds: 1000)),
        Word("klmno", const Duration(milliseconds: 1000)),
        Word("", const Duration(milliseconds: 1000)),
        Word("pqrst", const Duration(milliseconds: 1000)),
      ]),
    );

    final CursorBlinker cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {},
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

    void failedMessage(int index, TextPaneCursorController actual, TextPaneListCursor expected, bool reverse) {
      SentenceSelectionCursor resultCursor = actual.textPaneListCursor as SentenceSelectionCursor;
      SentenceSelectionCursor expectedCursor = expected as SentenceSelectionCursor;
      String order = reverse ? "backward" : "forward";
      debugPrint('Test failed at the $order iteration ${index + 1}:');
      debugPrint('Expected cursor position: ${expectedCursor.insertionPosition}, option: ${expectedCursor.option}');
      debugPrint('But the actual cursor position: ${resultCursor.insertionPosition}, option: ${resultCursor.option}');
    }

    bool cursorMatcher(SentenceSelectionCursorMover result, SentenceSelectionCursor expectedCursor) {
      if (result.textPaneCursor is! SentenceSelectionCursor) return false;

      SentenceSelectionCursor resultCursor = result.textPaneCursor as SentenceSelectionCursor;
      return resultCursor == expectedCursor;
    }

    bool checkCursor(TextPaneCursorController result, int index, List<PositionTestInfo> expectedMovement, bool reverse) {
      SentenceSelectionCursor expectedCursor = constructCursor(expectedMovement[index]);
      if (reverse) {
        result = result.moveLeftCursor();
      } else {
        result = result.moveRightCursor();
      }
      assert(result is SentenceSelectionCursorMover, "An unexpected state was occurred.");
      bool matcherResult = cursorMatcher(result as SentenceSelectionCursorMover, expectedCursor);
      if (!matcherResult) {
        failedMessage(index, result, expectedCursor, reverse);
        return false;
      }

      SentenceSelectionCursor resultCursor = result.textPaneCursor as SentenceSelectionCursor;
      debugPrint("movement: pos=${resultCursor.insertionPosition}, option=${resultCursor.option}");
      return true;
    }

    bool cursorMovementMatcher(TextPaneCursorController initialMover, List<PositionTestInfo> expectedMovement) {
      TextPaneCursorController result = initialMover;
      for (int index = 1; index < expectedMovement.length; index++) {
        bool success = checkCursor(result, index, expectedMovement, false);
        if (!success) return false;
        result = result.moveRightCursor();
      }
      bool success = checkCursor(result, expectedMovement.length - 1, expectedMovement, false);
      if (!success) return false;

      for (int index = expectedMovement.length - 2; index >= 0; index--) {
        bool success = checkCursor(result, index, expectedMovement, true);
        if (!success) return false;
        result = result.moveLeftCursor();
      }
      success = checkCursor(result, 0, expectedMovement, true);
      if (!success) return false;

      return true;
    }

    setUp(() {});

    test('Test to move left and right the text pane cursor No.1', () {
      final Sentence lyricSnippet = Sentence(
        vocalistID: VocalistID(1),
        timeline: timingData1,
        readingMap: ReadingMap.empty,
      );

      final SentenceSelectionCursor cursor = SentenceSelectionCursor(
        lyricSnippetID,
        cursorBlinker,
        InsertionPosition(1),
        Option.segment,
      );

      final SentenceSelectionCursorMover mover = SentenceSelectionCursorMover(
        lyricSnippetMap: SentenceMap({lyricSnippetID: lyricSnippet}),
        textPaneCursor: cursor,
        cursorBlinker: cursorBlinker,
        seekPosition: SeekPosition(2200),
      );

      SentenceSelectionCursorMover target = mover.copyWith();

      List<PositionTestInfo> expectedCursorMovement = [
        PositionTestInfo(1, Option.segment),
        PositionTestInfo(2, Option.segment),
        PositionTestInfo(3, Option.former),
        PositionTestInfo(5, Option.former),
        PositionTestInfo(12, Option.former),
        PositionTestInfo(12, Option.latter),
        PositionTestInfo(17, Option.former),
      ];

      expect(cursorMovementMatcher(target, expectedCursorMovement), true);
    });

    test('Test to move left and right the text pane cursor No.2', () {
      final Sentence lyricSnippet = Sentence(
        vocalistID: VocalistID(1),
        timeline: timingData2,
        readingMap: ReadingMap.empty,
      );

      final SentenceSelectionCursor cursor = SentenceSelectionCursor(
        lyricSnippetID,
        cursorBlinker,
        InsertionPosition(5),
        Option.former,
      );

      final SentenceSelectionCursorMover mover = SentenceSelectionCursorMover(
        lyricSnippetMap: SentenceMap({lyricSnippetID: lyricSnippet}),
        textPaneCursor: cursor,
        cursorBlinker: cursorBlinker,
        seekPosition: SeekPosition(6500),
      );

      SentenceSelectionCursorMover target = mover.copyWith();

      List<PositionTestInfo> expectedCursorMovement = [
        PositionTestInfo(5, Option.former),
        PositionTestInfo(5, Option.latter),
        PositionTestInfo(10, Option.former),
        PositionTestInfo(10, Option.latter),
        PositionTestInfo(11, Option.segment),
        PositionTestInfo(12, Option.segment),
        PositionTestInfo(13, Option.segment),
        PositionTestInfo(14, Option.segment),
        PositionTestInfo(15, Option.former),
        PositionTestInfo(15, Option.latter),
      ];

      expect(cursorMovementMatcher(target, expectedCursorMovement), true);
    });
  });
}
