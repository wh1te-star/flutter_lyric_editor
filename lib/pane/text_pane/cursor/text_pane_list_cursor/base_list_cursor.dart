import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/caret_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/ruby_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/service/timing_service.dart';

class BaseListCursor extends TextPaneListCursor {
  late CaretCursor caretCursor;
  BaseListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required AbsoluteSeekPosition seekPosition,
    required CaretPosition caretPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");

    Sentence sentence = sentenceMap.containsKey(sentenceID) ? sentenceMap[sentenceID]! : Sentence.empty;
    caretCursor = CaretCursor(
      timetable: sentence.timetable,
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

  BaseListCursor._privateConstructor(
    super.sentenceMap,
    super.sentenceID,
    super.seekPosition,
  );
  static final BaseListCursor _empty = BaseListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    AbsoluteSeekPosition.empty,
  );
  static BaseListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required AbsoluteSeekPosition seekPosition,
  }) {
    if (sentenceMap.isEmpty) {
      return BaseListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: AbsoluteSeekPosition.empty,
        caretPosition: CaretPosition.empty,
        option: Option.former,
      );
    }
    Sentence sentence = sentenceMap[sentenceID]!;
    CaretCursor defaultCursor = CaretCursor.defaultCursor(timetable: sentence.timetable, seekPosition: seekPosition);

    return BaseListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      caretPosition: defaultCursor.caretPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    Sentence sentence = sentenceMap[sentenceID]!;
    WordRange rubysWordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    if (rubysWordRange.isNotEmpty) {
      return RubyListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
        wordRange: rubysWordRange,
      );
    }

    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });
    if (index <= 0) {
      return this;
    }

    SentenceID nextSentenceID = sentenceMap.keys.toList()[index - 1];
    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: nextSentenceID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveDownCursor() {
    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });
    if (index >= sentenceMap.length) {
      return this;
    }

    SentenceID nextSentenceID = sentenceMap.keys.toList()[index + 1];
    Sentence nextSentence = sentenceMap[nextSentenceID]!;

    WordRange rubysWordRange = nextSentence.getRubysWordRangeFromSeekPosition(seekPosition);
    if (rubysWordRange.isNotEmpty) {
      return RubyListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
        wordRange: rubysWordRange,
      );
    }

    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: nextSentenceID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    CaretCursor nextCursor = caretCursor.moveLeftCursor() as CaretCursor;
    return BaseListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      caretPosition: nextCursor.caretPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    CaretCursor nextCursor = caretCursor.moveRightCursor() as CaretCursor;
    return BaseListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      caretPosition: nextCursor.caretPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor updateCursor(
    SentenceMap sentenceMap,
    SentenceID sentenceID,
    AbsoluteSeekPosition seekPosition,
  ) {
    if (sentenceMap.isEmpty) {
      return BaseListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: seekPosition,
        caretPosition: CaretPosition.empty,
        option: Option.former,
      );
    }

    if (!sentenceMap.containsKey(sentenceID)) {
      sentenceID = sentenceMap.keys.first;
    }
    Sentence sentence = sentenceMap[sentenceID]!;
    CaretPositionInfo caretPositionInfo = sentence.getCaretPositionInfo(caretCursor.caretPosition);
    SeekPositionInfo seekPositionInfo = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    if (caretPositionInfo is WordCaretPositionInfo && seekPositionInfo is WordSeekPositionInfo) {
      WordIndex incaretWordIndex = caretPositionInfo.wordIndex;
      WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
      if (incaretWordIndex == seekingWordIndex) {
        return BaseListCursor(
          sentenceMap: sentenceMap,
          sentenceID: sentenceID,
          seekPosition: seekPosition,
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

  TextPaneListCursor enterWordMode() {
    WordCursor nextCursor = caretCursor.enterWordMode() as WordCursor;
    return WordListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      wordRange: nextCursor.wordRange,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  BaseListCursor copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    AbsoluteSeekPosition? seekPosition,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return BaseListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      caretPosition: caretPosition ?? caretCursor.caretPosition,
      option: option ?? caretCursor.option,
    );
  }

  @override
  String toString() {
    return 'BaseListCursor(ID: ${sentenceID.id}, position: $caretCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseListCursor otherBaseListCursor = other as BaseListCursor;
    if (sentenceMap != otherBaseListCursor.sentenceMap) return false;
    if (sentenceID != otherBaseListCursor.sentenceID) return false;
    if (seekPosition != otherBaseListCursor.seekPosition) return false;
    if (caretCursor != otherBaseListCursor.caretCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ caretCursor.hashCode;
}
