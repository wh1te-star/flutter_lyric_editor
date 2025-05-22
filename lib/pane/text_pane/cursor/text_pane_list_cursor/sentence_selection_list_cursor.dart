import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/reading_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

class SentenceSelectionListCursor extends TextPaneListCursor {
  late SentenceSelectionCursor sentenceSelectionCursor;
  SentenceSelectionListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");

    Sentence sentence = sentenceMap.containsKey(sentenceID) ? sentenceMap[sentenceID]! : Sentence.empty;
    sentenceSelectionCursor = SentenceSelectionCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: option,
    );
    textPaneCursor = sentenceSelectionCursor;
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

  SentenceSelectionListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final SentenceSelectionListCursor _empty = SentenceSelectionListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    SeekPosition.empty,
  );
  static SentenceSelectionListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory SentenceSelectionListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
  }) {
    if (sentenceMap.isEmpty) {
      return SentenceSelectionListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: SeekPosition.empty,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }
    Sentence sentence = sentenceMap[sentenceID]!;
    WordIndex segmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = sentence.timeline.leftTiming(segmentIndex).insertionPosition + 1;
    return SentenceSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    Sentence lyricSnippet = sentenceMap[sentenceID]!;
    PhrasePosition readingIndex = lyricSnippet.getPhraseFromSeekPosition(seekPosition);
    if (readingIndex.isNotEmpty) {
      return ReadingSelectionListCursor.defaultCursor(
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

    SentenceID nextLyricSnippetID = sentenceMap.keys.toList()[index - 1];
    return SentenceSelectionListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: nextLyricSnippetID,
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

    PhrasePosition readingIndex = nextSentence.getPhraseFromSeekPosition(seekPosition);
    if (readingIndex.isNotEmpty) {
      return ReadingSelectionListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: nextSentenceID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    SentenceSelectionCursor nextCursor = sentenceSelectionCursor.moveLeftCursor() as SentenceSelectionCursor;
    return SentenceSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    SentenceSelectionCursor nextCursor = sentenceSelectionCursor.moveRightCursor() as SentenceSelectionCursor;
    return SentenceSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
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
      return SentenceSelectionListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: seekPosition,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    if (!sentenceMap.containsKey(sentenceID)) {
      sentenceID = sentenceMap.keys.first;
    }
    Sentence lyricSnippet = sentenceMap[sentenceID]!;
    WordIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo(sentenceSelectionCursor.insertionPosition);
    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return SentenceSelectionListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: sentenceID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      insertionPosition: sentenceSelectionCursor.insertionPosition,
      option: sentenceSelectionCursor.option,
    );
  }

  TextPaneListCursor enterSegmentSelectionMode() {
    SegmentSelectionCursor nextCursor = sentenceSelectionCursor.enterSegmentSelectionMode() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  SentenceSelectionListCursor copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return SentenceSelectionListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? sentenceSelectionCursor.insertionPosition,
      option: option ?? sentenceSelectionCursor.option,
    );
  }

  @override
  String toString() {
    return 'SentenceSelectionCursor(ID: ${sentenceID.id}, position: $sentenceSelectionCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionListCursor otherSentenceSegments = other as SentenceSelectionListCursor;
    if (sentenceMap != otherSentenceSegments.sentenceMap) return false;
    if (sentenceID != otherSentenceSegments.sentenceID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (sentenceSelectionCursor != otherSentenceSegments.sentenceSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ sentenceSelectionCursor.hashCode;
}
