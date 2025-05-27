import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/ruby_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/service/timing_service.dart';

class RubyListCursor extends TextPaneListCursor {
  late RubyCursor rubyCursor;

  RubyListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required WordRange wordRange,
    required CaretPosition caretPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");
    assert(doesSeekPositionPointRuby(), "The passed seek position does not point to any ruby.");
    rubyCursor = RubyCursor(
      sentence: sentenceMap[sentenceID]!,
      seekPosition: seekPosition,
      wordRange: wordRange,
      caretPosition: caretPosition,
      option: option,
    );
    textPaneCursor = rubyCursor;
  }

  bool isIDContained() {
    if (sentenceMap.isEmpty) {
      return true;
    }
    Sentence? sentence = sentenceMap[sentenceID];
    if (sentence == null) {
      return false;
    }
    return true;
  }

  RubyListCursor._privateConstructor(
    super.sentenceMap,
    super.sentenceID,
    super.seekPosition,
  );
  static final RubyListCursor _empty = RubyListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    SeekPosition.empty,
  );
  static RubyListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  bool doesSeekPositionPointRuby() {
    Sentence sentence = sentenceMap[sentenceID]!;
    WordRange rubyWordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    return rubyWordRange.isNotEmpty;
  }

  factory RubyListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
  }) {
    Sentence sentence = sentenceMap.getSentenceByID(sentenceID);
    WordRange rubysWordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    Ruby ruby = sentence.rubyMap[rubysWordRange]!;
    WordIndex wordIndex = ruby.getSeekPositionInfoBySeekPosition(seekPosition);

    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: rubysWordRange,
      caretPosition: ruby.timetable.getLeftTiming(wordIndex).caretPosition + 1,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });

    int nextIndex = index - 1;
    if (nextIndex < 0) {
      return this;
    }

    SentenceID nextSentenceID = sentenceMap.keys.toList()[nextIndex];
    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: nextSentenceID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveDownCursor() {
    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    RubyCursor nextCursor = rubyCursor.moveLeftCursor() as RubyCursor;
    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: nextCursor.wordRange,
      caretPosition: nextCursor.caretPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    RubyCursor nextCursor = rubyCursor.moveRightCursor() as RubyCursor;
    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: nextCursor.wordRange,
      caretPosition: nextCursor.caretPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor updateCursor(
    SentenceMap sentenceMap,
    SentenceID sentenceID,
    SeekPosition seekPosition,
  ) {
    if (sentenceMap.isEmpty) {
      return RubyListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: seekPosition,
        wordRange: WordRange.empty,
        caretPosition: CaretPosition.empty,
        option: Option.former,
      );
    }

    SentenceID nextSentenceID = sentenceMap.keys.first;
    Sentence nextSentence = sentenceMap.values.first;
    if (sentenceMap.containsKey(sentenceID)) {
      nextSentenceID = sentenceID;
      nextSentence = sentenceMap[sentenceID]!;
    }

    WordIndex currentSeekWordIndex = nextSentence.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPositionInfo nextSentencePositionInfo = nextSentence.getCaretPositionInfo(rubyCursor.caretPosition);

    if (nextSentencePositionInfo is InvalidCaretPositionInfo || nextSentencePositionInfo is WordCaretPositionInfo && nextSentencePositionInfo.wordIndex != currentSeekWordIndex) {
      return RubyListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: nextSentenceID,
        seekPosition: seekPosition,
      );
    }

    return this;
  }

  RubyListCursor copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    SeekPosition? seekPosition,
    WordRange? wordRange,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return RubyListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      wordRange: wordRange ?? rubyCursor.wordRange,
      caretPosition: caretPosition ?? rubyCursor.caretPosition,
      option: option ?? rubyCursor.option,
    );
  }

  @override
  String toString() {
    return 'RubyListCursor(ID: ${sentenceID.id}, $rubyCursor';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyListCursor otherRubyListCursor = other as RubyListCursor;
    if (sentenceMap != otherRubyListCursor.sentenceMap) return false;
    if (sentenceID != otherRubyListCursor.sentenceID) return false;
    if (seekPosition != otherRubyListCursor.seekPosition) return false;
    if (rubyCursor != otherRubyListCursor.rubyCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ rubyCursor.hashCode;
}
