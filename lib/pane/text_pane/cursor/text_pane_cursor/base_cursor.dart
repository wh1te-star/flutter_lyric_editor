import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class BaseCursor extends TextPaneCursor {
  InsertionPosition insertionPosition;
  Option option;

  BaseCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition);

  BaseCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.insertionPosition,
    this.option,
  );
  static final BaseCursor _empty = BaseCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static BaseCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
    WordIndex wordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = sentence.timetable.leftTimingPoint(wordIndex).insertionPosition + 1;
    return BaseCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    InsertionPositionInfo? insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is WordInsertionPositionInfo) {
      WordIndex wordIndex = insertionPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition - 1;
      if (nextInsertionPosition <= InsertionPosition(0)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      if (option == Option.latter) {
        return copyWith(option: Option.former);
      }

      TimingPointIndex rightTimingPointIndex = sentence.timetable.rightTimingPointIndex(highlightWordIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (timingPointIndex == rightTimingPointIndex) {
        nextInsertionPosition = insertionPosition - 1;
      } else {
        if (timingPointIndex.index - 1 <= 0) {
          return this;
        }
        TimingPoint previousTimingPoint = sentence.timingPoints[timingPointIndex.index - 1];
        nextInsertionPosition = previousTimingPoint.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is WordInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.word);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      Option nextOption = Option.former;
      if (nextInsertionPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      return copyWith(insertionPosition: nextInsertionPosition, option: nextOption);
    }

    return this;
  }

  @override
  TextPaneCursor moveRightCursor() {
    InsertionPositionInfo? insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is WordInsertionPositionInfo) {
      WordIndex wordIndex = insertionPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition + 1;
      if (nextInsertionPosition >= InsertionPosition(sentence.sentence.length)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      if (insertionPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingPointIndex leftTimingPointIndex = sentence.timetable.leftTimingPointIndex(highlightWordIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (insertionPositionInfo.duplicate) timingPointIndex = timingPointIndex + 1;
      if (timingPointIndex == leftTimingPointIndex) {
        nextInsertionPosition = insertionPosition + 1;
      } else {
        TimingPointIndex nextTimingPointIndex = timingPointIndex + 1;
        if (nextTimingPointIndex.index >= sentence.timingPoints.length - 1) {
          return this;
        }
        TimingPoint nextTimingPoint = sentence.timingPoints[nextTimingPointIndex.index];
        nextInsertionPosition = nextTimingPoint.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is WordInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.word);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.former);
    }

    return this;
  }

  TextPaneCursor enterWordMode() {
    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: PhrasePosition(WordIndex(0), WordIndex(0)),
      isExpandMode: false,
    );
  }

  @override
  List<TextPaneCursor?> getPhrasePositionDividedCursors(Sentence sentence, List<PhrasePosition> phrasePositionList) {
    List<BaseCursor?> separatedCursors = List.filled(phrasePositionList.length, null);
    BaseCursor shiftedCursor = copyWith();
    for (int index = 0; index < phrasePositionList.length; index++) {
      PhrasePosition phrasePosition = phrasePositionList[index];
      WordList? sentenceSubList = sentence.getWordList(phrasePosition);
      BaseCursor? nextCursor = shiftedCursor.shiftLeftByWordList(sentenceSubList);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList) {
    List<BaseCursor?> separatedCursors = List.filled(wordList.length, null);
    BaseCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordList.length; index++) {
      Word word = wordList[index];
      BaseCursor? nextCursor = shiftedCursor.shiftLeftByWord(word);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  BaseCursor? shiftLeftByWordList(WordList wordList) {
    if (insertionPosition.position - wordList.charCount < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - wordList.charCount;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  @override
  BaseCursor? shiftLeftByWord(Word word) {
    if (insertionPosition.position - word.word.length < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - word.word.length;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  BaseCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return BaseCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'BaseCursor(position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseCursor otherWords = other as BaseCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (insertionPosition != otherWords.insertionPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
