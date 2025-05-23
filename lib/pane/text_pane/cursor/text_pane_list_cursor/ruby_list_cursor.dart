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
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

class RubyListCursor extends TextPaneListCursor {
  late RubyCursor rubyCursor;

  RubyListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required PhrasePosition phrasePosition,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");
    assert(doesSeekPositionPointAnnotation(), "The passed seek position does not point to any annotation.");
    rubyCursor = RubyCursor(
      sentence: sentenceMap[sentenceID]!,
      seekPosition: seekPosition,
      phrasePosition: phrasePosition,
      insertionPosition: insertionPosition,
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

  bool doesSeekPositionPointAnnotation() {
    Sentence sentence = sentenceMap[sentenceID]!;
    PhrasePosition rubyPhrasePosition = sentence.getRubysPhrasePositionFromSeekPosition(seekPosition);
    return rubyPhrasePosition.isNotEmpty;
  }

  factory RubyListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
  }) {
    Sentence sentence = sentenceMap.getSentenceByID(sentenceID);
    PhrasePosition rubyPhrasePosition = sentence.getRubysPhrasePositionFromSeekPosition(seekPosition);
    Annotation annotation = sentence.annotationMap[rubyPhrasePosition]!;
    SentenceSegmentIndex segmentIndex = annotation.getSegmentIndexFromSeekPosition(seekPosition);

    return RubyListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrasePosition: rubyPhrasePosition,
      insertionPosition: annotation.timing.leftTimingPoint(segmentIndex).insertionPosition + 1,
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
    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });

    int nextIndex = index + 1;
    if (nextIndex >= sentenceMap.length) {
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
  TextPaneListCursor moveLeftCursor() {
    return this;
  }

  @override
  TextPaneListCursor moveRightCursor() {
    return this;
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
        phrasePosition: PhrasePosition.empty,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    SentenceID nextSentenceID = sentenceMap.keys.first;
    Sentence sentence = sentenceMap.values.first;
    if (sentenceMap.containsKey(nextSentenceID)) {
      nextSentenceID = sentenceID;
      sentence = sentenceMap[nextSentenceID]!;
    }

    SentenceSegmentIndex currentSeekSegmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSentencePositionInfo = sentence.getInsertionPositionInfo(rubyCursor.insertionPosition);

    if (nextSentencePositionInfo == null || nextSentencePositionInfo is SentenceSegmentInsertionPositionInfo && nextSentencePositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
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
    PhrasePosition? phrasePosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return RubyListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      phrasePosition: phrasePosition ?? rubyCursor.phrasePosition,
      insertionPosition: insertionPosition ?? rubyCursor.insertionPosition,
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
    final RubyListCursor otherSentenceSegments = other as RubyListCursor;
    if (sentenceMap != otherSentenceSegments.sentenceMap) return false;
    if (sentenceID != otherSentenceSegments.sentenceID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (rubyCursor != otherSentenceSegments.rubyCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ rubyCursor.hashCode;
}
