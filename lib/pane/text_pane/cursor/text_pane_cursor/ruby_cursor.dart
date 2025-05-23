import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class RubyCursor extends TextPaneCursor {
  PhrasePosition phrasePosition;
  InsertionPosition insertionPosition;
  Option option;

  RubyCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.phrasePosition,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition) {
    assert(doesSeekPositionPointRuby(), "The passed seek position does not point to any ruby.");
  }

  bool doesSeekPositionPointRuby() {
    PhrasePosition phrasePosition = sentence.getRubysPhrasePositionFromSeekPosition(seekPosition);
    return phrasePosition.isNotEmpty;
  }

  RubyCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.phrasePosition,
    this.insertionPosition,
    this.option,
  );
  static final RubyCursor _empty = RubyCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    PhrasePosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static RubyCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory RubyCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
    PhrasePosition phrasePosition = sentence.getRubysPhrasePositionFromSeekPosition(seekPosition);
    Ruby ruby = sentence.rubyMap[phrasePosition]!;
    WordIndex wordIndex = ruby.getWordIndexFromSeekPosition(seekPosition);

    return RubyCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: phrasePosition,
      insertionPosition: ruby.timetable.leftTimingPoint(wordIndex).insertionPosition + 1,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    return this;
  }

  @override
  TextPaneCursor moveRightCursor() {
    return this;
  }

  @override
  List<TextPaneCursor?> getPhrasePositionDividedCursors(Sentence sentence, List<PhrasePosition> phrasePositionList) {
    List<RubyCursor?> separatedCursors = List.filled(phrasePositionList.length, null);
    RubyCursor cursor = copyWith();
    for (int index = 0; index < phrasePositionList.length; index++) {
      PhrasePosition phrasePosition = phrasePositionList[index];
      if (phrasePosition == cursor.phrasePosition) {
        separatedCursors[index] = cursor;
        break;
      }
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList) {
    List<RubyCursor?> separatedCursors = List.filled(wordList.length, null);
    return separatedCursors;
  }

  @override
  RubyCursor? shiftLeftByWordList(WordList wordList) {
    return this;
  }

  @override
  RubyCursor? shiftLeftByWord(Word word) {
    return this;
  }

  RubyCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    PhrasePosition? phrasePosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return RubyCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      phrasePosition: phrasePosition ?? this.phrasePosition,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'RubyCursor($sentence, phrasePosition: $phrasePosition, position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyCursor otherWords = other as RubyCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (phrasePosition != otherWords.phrasePosition) return false;
    if (insertionPosition != otherWords.insertionPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ phrasePosition.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
