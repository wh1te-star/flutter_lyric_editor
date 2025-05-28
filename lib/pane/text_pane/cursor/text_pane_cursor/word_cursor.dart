import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';

class WordCursor extends TextPaneCursor {
  WordRange wordRange;
  bool isExpandMode = false;

  WordCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.wordRange,
    required this.isExpandMode,
  }) : super(sentence, seekPosition);

  WordCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.wordRange,
    this.isExpandMode,
  );
  static final WordCursor _empty = WordCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    WordRange.empty,
    false,
  );
  static WordCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  WordCursor defaultCursor() {
    WordIndex wordIndex = WordIndex(0);
    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: WordRange(wordIndex, wordIndex),
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    WordRange nextWordRange = wordRange.copyWith();

    if (!isExpandMode) {
      WordIndex currentIndex = wordRange.startIndex;
      WordIndex nextIndex = currentIndex - 1;
      if (nextIndex < WordIndex(0)) {
        return this;
      }
      nextWordRange.startIndex = nextIndex;

      nextWordRange.endIndex = wordRange.endIndex - 1;
    } else {
      WordIndex currentIndex = wordRange.endIndex;
      WordIndex nextIndex = currentIndex - 1;
      if (nextIndex < wordRange.startIndex) {
        return this;
      }
      nextWordRange.startIndex = wordRange.startIndex;
      nextWordRange.endIndex = nextIndex;
    }

    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: nextWordRange,
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveRightCursor() {
    WordRange nextWordRange = wordRange.copyWith();

    WordIndex currentIndex = wordRange.endIndex;
    WordIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= sentence.words.length) {
      return this;
    }

    nextWordRange.endIndex = nextIndex;
    if (!isExpandMode) {
      nextWordRange.startIndex = wordRange.startIndex + 1;
    }

    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: nextWordRange,
      isExpandMode: isExpandMode,
    );
  }

  TextPaneCursor exitWordMode() {
    return BaseCursor.defaultCursor(
      sentence: sentence,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToExpandMode() {
    bool isExpandMode = !this.isExpandMode;
    return copyWith(isExpandMode: isExpandMode);
  }

  @override
  List<TextPaneCursor?> getWordRangeDividedCursors(Sentence sentence, List<WordRange> wordRangeList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(wordRangeList.length, null);

    int startWordRangeIndex = wordRangeList.indexWhere((WordRange wordRange) {
      return wordRange.isInRange(cursor.wordRange.startIndex);
    });
    int endWordRangeIndex = wordRangeList.indexWhere((WordRange wordRange) {
      return wordRange.isInRange(cursor.wordRange.endIndex);
    });

    int shiftLength = 0;
    for (int index = 0; index <= endWordRangeIndex; index++) {
      WordIndex startIndex = wordRangeList[index].startIndex - shiftLength;
      WordIndex endIndex = wordRangeList[index].endIndex - shiftLength;
      if (index == startWordRangeIndex) {
        startIndex = cursor.wordRange.startIndex - shiftLength;
      }
      if (index == endWordRangeIndex) {
        endIndex = cursor.wordRange.endIndex - shiftLength;
      }

      if (startWordRangeIndex <= index && index <= endWordRangeIndex) {
        separatedCursors[index] = cursor.copyWith(
          wordRange: WordRange(startIndex, endIndex),
        );
      }
      shiftLength += wordRangeList[index].length;
    }

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(wordList.length, null);
    WordCursor initialCursor = WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: WordRange(WordIndex(0), WordIndex(0)),
      isExpandMode: isExpandMode,
    );
    for (int index = 0; index < wordList.length; index++) {
      WordIndex wordIndex = WordIndex(index);
      if (cursor.wordRange.isInRange(wordIndex)) {
        separatedCursors[index] = initialCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  WordCursor shiftLeftByWordList(WordList wordList) {
    if (wordRange.startIndex.index - 1 < 0 || wordRange.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    WordIndex startIndex = wordRange.startIndex - wordList.wordCount;
    WordIndex endIndex = wordRange.endIndex - wordList.wordCount;
    WordRange newWordRange = WordRange(startIndex, endIndex);
    return copyWith(wordRange: newWordRange);
  }

  @override
  WordCursor shiftLeftByWord(Word word) {
    if (wordRange.startIndex.index - 1 < 0 || wordRange.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    WordIndex startIndex = wordRange.startIndex - 1;
    WordIndex endIndex = wordRange.endIndex - 1;
    WordRange newWordRange = WordRange(startIndex, endIndex);
    return copyWith(wordRange: newWordRange);
  }

  WordCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    WordRange? wordRange,
    bool? isExpandMode,
  }) {
    return WordCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      wordRange: wordRange ?? this.wordRange,
      isExpandMode: isExpandMode ?? this.isExpandMode,
    );
  }

  @override
  String toString() {
    return 'WordCursor(ID: $sentence, wordIndex: $wordRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final WordCursor otherWords = other as WordCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (wordRange != otherWords.wordRange) return false;
    if (isExpandMode != otherWords.isExpandMode) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ wordRange.hashCode ^ isExpandMode.hashCode;
}
