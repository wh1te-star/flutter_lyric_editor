import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/caret_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/ruby_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/word_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/timing_edit.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

class SentenceEdit extends StatelessWidget {
  final Sentence sentence;
  final SeekPosition seekPosition;
  final TextPaneListCursor? textPaneListCursor;
  final CursorBlinker cursorBlinker;
  SentenceEdit(this.sentence, this.seekPosition, this.textPaneListCursor, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> rubyExistenceEdits = [];
    List<Tuple2<WordRange, Ruby?>> rubyWordRangeList = sentence.getRubysWordRangeList();
    List<WordRange> wordRangeList = rubyWordRangeList.map((Tuple2<WordRange, Ruby?> entry) {
      return entry.item1;
    }).toList();
    List<TextPaneCursor?> baseCursorList = List.filled(wordRangeList.length, null);
    baseCursorList = textPaneListCursor!.textPaneCursor.getWordRangeDividedCursors(sentence.timetable, wordRangeList);

    for (int index = 0; index < rubyWordRangeList.length; index++) {
      WordRange wordRange = rubyWordRangeList[index].item1;
      Ruby? ruby = rubyWordRangeList[index].item2;

      WordList? baseSubList = sentence.getWordList(wordRange);
      WordList? rubySubList = ruby?.timetable.wordList;

      TextPaneCursor? cursor = baseCursorList[index];
      bool isTimingPosition = false;
      if (cursor is CaretCursor && cursor.caretPosition == CaretPosition(0)) {
        isTimingPosition = true;
      }

      CursorBlinker? timingCursorBlinker;
      CursorBlinker? wordListCursorBlinker;
      TextPaneCursor? baseCursor;
      TextPaneCursor? rubyCursor;
      if (isTimingPosition) {
        timingCursorBlinker = cursorBlinker;
      } else {
        wordListCursorBlinker = cursorBlinker;
        if (textPaneListCursor is RubyListCursor) {
          rubyCursor = textPaneListCursor!.textPaneCursor;
        } else {
          baseCursor = cursor;
        }
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
        wordListCursorBlinker,
      );
      Widget rubyEdit = getRubyEdit(
        rubySubList,
        rubyCursor,
        wordListCursorBlinker,
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
    if (textPaneListCursor is RubyListCursor) {
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
    if (textPaneListCursor is! RubyListCursor) {
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
