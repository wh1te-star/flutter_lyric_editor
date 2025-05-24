import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/ruby_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/word_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/timing_edit.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

class SentenceEdit extends StatelessWidget {
  final Sentence sentence;
  final SeekPosition seekPosition;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker cursorBlinker;
  SentenceEdit(this.sentence, this.seekPosition, this.textPaneCursor, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> rubyExistenceEdits = [];
    List<Tuple2<WordRange, Ruby?>> rubyWordRangeList = sentence.getRubysWordRangeList();
    List<WordRange> wordRangeList = rubyWordRangeList.map((Tuple2<WordRange, Ruby?> entry) {
      return entry.item1;
    }).toList();
    List<TextPaneCursor?> cursorList = List.filled(wordRangeList.length, null);
    cursorList = textPaneCursor!.getWordRangeDividedCursors(sentence, wordRangeList);

    for (int index = 0; index < rubyWordRangeList.length; index++) {
      WordRange wordRange = rubyWordRangeList[index].item1;
      Ruby? ruby = rubyWordRangeList[index].item2;

      WordList? baseSubList = sentence.getWordList(wordRange);
      WordList? rubySubList = ruby?.timetable.wordList;

      TextPaneCursor? cursor = cursorList[index];
      bool isTimingPosition = false;
      if (cursor is BaseCursor && cursor.caretPosition == CaretPosition(0)) {
        isTimingPosition = true;
      }

      CursorBlinker? timingCursorBlinker;
      CursorBlinker? baseCursorBlinker;
      TextPaneCursor? baseCursor;
      CursorBlinker? rubyCursorBlinker;
      TextPaneCursor? rubyCursor;
      if (isTimingPosition) {
        timingCursorBlinker = cursorBlinker;
      } else if (textPaneCursor is! RubyCursor) {
        baseCursorBlinker = cursorBlinker;
        baseCursor = cursor;
      } else {
        rubyCursorBlinker = cursorBlinker;
        rubyCursor = cursor;
      }

      if (index > 0) {
        rubyExistenceEdits.add(Column(
          children: [
            TimingEdit(
              timing: false,
              cursorBlinker: timingCursorBlinker,
            ),
            TimingEdit(
              timing: false,
              cursorBlinker: timingCursorBlinker,
            ),
          ],
        ));
      }

      Widget baseEdit = getSentenceEdit(
        baseSubList,
        baseCursor,
        baseCursorBlinker,
      );
      Widget rubyEdit = getRubyEdit(
        rubySubList,
        rubyCursor,
        rubyCursorBlinker,
      );
      rubyExistenceEdits.add(Column(children: [
        rubyEdit,
        baseEdit,
      ]));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: rubyExistenceEdits,
    );
  }

  Widget getSentenceEdit(
    WordList wordList,
    TextPaneCursor? textPaneCursor,
    CursorBlinker? cursorBlinker,
  ) {
    if (textPaneCursor is! BaseCursor && textPaneCursor is! WordCursor) {
      textPaneCursor = null;
      cursorBlinker = null;
    }

    return WordListEdit(
      wordList: wordList,
      textPaneCursor: textPaneCursor,
      cursorBlinker: cursorBlinker,
    );
  }

  Widget getRubyEdit(
    WordList? wordList,
    TextPaneCursor? textPaneCursor,
    CursorBlinker? cursorBlinker,
  ) {
    if (textPaneCursor is! RubyCursor) {
      textPaneCursor = null;
      cursorBlinker = null;
    }

    Widget rubyEdit = Container();
    if (wordList != null) {
      rubyEdit = WordListEdit(
        wordList: wordList,
        textPaneCursor: textPaneCursor,
        cursorBlinker: cursorBlinker,
      );
    }
    return rubyEdit;
  }
}
