import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/caret_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/service/timing_service.dart';

class RubyListCursor extends TextPaneListCursor {
  late CaretCursor caretCursor;
  WordRange wordRange;

  RubyListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required this.wordRange,
    required CaretPosition caretPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");
    assert(doesSeekPositionPointRuby(), "The passed seek position does not point to any ruby.");
    caretCursor = CaretCursor(
      timetable: sentenceMap[sentenceID]!.rubyMap[wordRange]!.timetable,
      seekPosition: seekPosition,
      caretPosition: caretPosition,
      option: option,
    );
    textPaneCursor = caretCursor;
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

  bool doesSeekPositionPointRuby() {
    Sentence sentence = sentenceMap[sentenceID]!;
    WordRange rubyWordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    return rubyWordRange.isNotEmpty;
  }

  RubyListCursor._privateConstructor(
    super.sentenceMap,
    super.sentenceID,
    super.seekPosition,
    this.wordRange,
  );
  static final RubyListCursor _empty = RubyListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    SeekPosition.empty,
    WordRange.empty,
  );
  static RubyListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory RubyListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required WordRange wordRange,
  }) {
    if (sentenceMap.isEmpty) {
      return RubyListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: SeekPosition.empty,
        wordRange: WordRange.empty,
        caretPosition: CaretPosition.empty,
        option: Option.former,
      );
    }

    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: wordRange,
      caretPosition: CaretPosition(1),
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
    CaretCursor nextCursor = caretCursor.moveLeftCursor() as CaretCursor;
    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: wordRange,
      caretPosition: nextCursor.caretPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    CaretCursor nextCursor = caretCursor.moveRightCursor() as CaretCursor;
    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: wordRange,
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

    if (!sentenceMap.containsKey(sentenceID)) {
      sentenceID = sentenceMap.keys.first;
    }
    Sentence sentence = sentenceMap[sentenceID]!;
    WordRange seekingWordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    if (seekingWordRange != wordRange) {
      if (seekingWordRange.isEmpty) {
        return BaseListCursor(
          sentenceMap: sentenceMap,
          sentenceID: sentenceID,
          seekPosition: seekPosition,
          caretPosition: caretCursor.caretPosition,
          option: caretCursor.option,
        );
      } else {
        return RubyListCursor(
          sentenceMap: sentenceMap,
          sentenceID: sentenceID,
          seekPosition: seekPosition,
          wordRange: seekingWordRange,
          caretPosition: caretCursor.caretPosition,
          option: caretCursor.option,
        );
      }
    }

    CaretPositionInfo caretPositionInfo = sentence.getCaretPositionInfo(caretCursor.caretPosition);
    SeekPositionInfo seekPositionInfo = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    if (caretPositionInfo is WordCaretPositionInfo && seekPositionInfo is WordSeekPositionInfo) {
      WordIndex incaretWordIndex = caretPositionInfo.wordIndex;
      WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
      if (incaretWordIndex == seekingWordIndex) {
        return RubyListCursor(
          sentenceMap: sentenceMap,
          sentenceID: sentenceID,
          seekPosition: seekPosition,
          wordRange: wordRange,
          caretPosition: caretCursor.caretPosition,
          option: caretCursor.option,
        );
      }
    }

    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
    );
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
      wordRange: wordRange ?? this.wordRange,
      caretPosition: caretPosition ?? caretCursor.caretPosition,
      option: option ?? caretCursor.option,
    );
  }

  @override
  String toString() {
    return 'RubyListCursor(ID: ${sentenceID.id}, $caretCursor';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyListCursor otherRubyListCursor = other as RubyListCursor;
    if (sentenceMap != otherRubyListCursor.sentenceMap) return false;
    if (sentenceID != otherRubyListCursor.sentenceID) return false;
    if (seekPosition != otherRubyListCursor.seekPosition) return false;
    if (caretCursor != otherRubyListCursor.caretCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ caretCursor.hashCode;
}
