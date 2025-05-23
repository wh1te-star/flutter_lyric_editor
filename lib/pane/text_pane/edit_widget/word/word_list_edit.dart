import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/word_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/timing_edit.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class WordListEdit extends StatelessWidget {
  final WordList wordList;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker? cursorBlinker;

  const WordListEdit({
    required this.wordList,
    this.textPaneCursor,
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> editWidgets = [];
    List<Word> words = wordList.list;
    List<TextPaneCursor?> cursorList = List.filled(wordList.length, null);
    if (textPaneCursor != null) {
      cursorList = textPaneCursor!.getWordDividedCursors(wordList);
    }

    for (int index = 0; index < words.length; index++) {
      Word word = words[index];
      TextPaneCursor? wordCursor = cursorList[index];

      bool isTimingPointPosition = false;
      if (wordCursor is BaseCursor && wordCursor.insertionPosition.position == 0) {
        isTimingPointPosition = true;
      }

      if (index > 0) {
        editWidgets.add(TimingPointEdit(
          cursorBlinker: isTimingPointPosition ? cursorBlinker : null,
        ));
      }

      editWidgets.add(
        WordEdit(
          word: word,
          textPaneCursor: !isTimingPointPosition ? wordCursor : null,
          cursorBlinker: cursorBlinker,
        ),
      );
    }

    return Row(children: editWidgets);
  }
}
