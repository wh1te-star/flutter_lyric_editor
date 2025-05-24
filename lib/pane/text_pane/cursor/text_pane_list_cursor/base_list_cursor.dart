import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/ruby_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_list_cursor.dart';
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

class BaseListCursor extends TextPaneListCursor {
  late BaseCursor baseCursor;
  BaseListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required CaretPosition caretPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");

    Sentence sentence = sentenceMap.containsKey(sentenceID) ? sentenceMap[sentenceID]! : Sentence.empty;
    baseCursor = BaseCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      caretPosition: caretPosition,
      option: option,
    );
    textPaneCursor = baseCursor;
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
    SeekPosition.empty,
  );
  static BaseListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
  }) {
    if (sentenceMap.isEmpty) {
      return BaseListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: SeekPosition.empty,
        caretPosition: CaretPosition.empty,
        option: Option.former,
      );
    }
    Sentence sentence = sentenceMap.getSentenceByID(sentenceID);
    WordIndex wordIndex = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPosition caretPosition = sentence.timetable.getLeftTiming(wordIndex).caretPosition + 1;
    return BaseListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      caretPosition: caretPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    Sentence sentence = sentenceMap[sentenceID]!;
    WordRange rubyIndex = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    if (rubyIndex.isNotEmpty) {
      return RubyListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
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

    WordRange rubyIndex = nextSentence.getRubysWordRangeFromSeekPosition(seekPosition);
    if (rubyIndex.isNotEmpty) {
      return RubyListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
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
    BaseCursor nextCursor = baseCursor.moveLeftCursor() as BaseCursor;
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
    BaseCursor nextCursor = baseCursor.moveRightCursor() as BaseCursor;
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
    SeekPosition seekPosition,
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
    WordIndex currentSeekWordIndex = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPositionInfo nextSentencePositionInfo = sentence.getCaretPositionInfo(baseCursor.caretPosition);
    if (nextSentencePositionInfo is InvalidCaretPositionInfo || nextSentencePositionInfo is WordCaretPositionInfo && nextSentencePositionInfo.wordIndex != currentSeekWordIndex) {
      return BaseListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
      );
    }

    return BaseListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      caretPosition: baseCursor.caretPosition,
      option: baseCursor.option,
    );
  }

  TextPaneListCursor enterWordMode() {
    WordCursor nextCursor = baseCursor.enterWordMode() as WordCursor;
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
    SeekPosition? seekPosition,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return BaseListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      caretPosition: caretPosition ?? baseCursor.caretPosition,
      option: option ?? baseCursor.option,
    );
  }

  @override
  String toString() {
    return 'BaseListCursor(ID: ${sentenceID.id}, position: $baseCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseListCursor otherBaseListCursor = other as BaseListCursor;
    if (sentenceMap != otherBaseListCursor.sentenceMap) return false;
    if (sentenceID != otherBaseListCursor.sentenceID) return false;
    if (seekPosition != otherBaseListCursor.seekPosition) return false;
    if (baseCursor != otherBaseListCursor.baseCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ baseCursor.hashCode;
}
