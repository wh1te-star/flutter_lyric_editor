import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/reading_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/sentence_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

class ReadingSelectionListCursor extends TextPaneListCursor {
  late ReadingSelectionCursor readingSelectionCursor;

  ReadingSelectionListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required PhrasePosition phrase,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
    assert(doesSeekPositionPointReading(), "The passed seek position does not point to any reading.");
    readingSelectionCursor = ReadingSelectionCursor(
      sentence: sentenceMap[sentenceID]!,
      seekPosition: seekPosition,
      phrase: phrase,
      insertionPosition: insertionPosition,
      option: option,
    );
    textPaneCursor = readingSelectionCursor;
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

  ReadingSelectionListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final ReadingSelectionListCursor _empty = ReadingSelectionListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    SeekPosition.empty,
  );
  static ReadingSelectionListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  bool doesSeekPositionPointReading() {
    Sentence sentence = sentenceMap[sentenceID]!;
    PhrasePosition readingPhrase = sentence.getPhraseFromSeekPosition(seekPosition);
    return readingPhrase.isNotEmpty;
  }

  factory ReadingSelectionListCursor.defaultCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
  }) {
    Sentence sentence = sentenceMap[sentenceID]!;
    PhrasePosition readingPhrase = sentence.getPhraseFromSeekPosition(seekPosition);
    Reading reading = sentence.readingMap[readingPhrase]!;
    WordIndex segmentIndex = reading.getSegmentIndexFromSeekPosition(seekPosition);

    return ReadingSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrase: readingPhrase,
      insertionPosition: reading.timeline.leftTiming(segmentIndex).insertionPosition + 1,
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
    return SentenceSelectionListCursor.defaultCursor(
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
    return SentenceSelectionListCursor.defaultCursor(
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
      return ReadingSelectionListCursor(
        sentenceMap: SentenceMap.empty,
        sentenceID: SentenceID.empty,
        seekPosition: seekPosition,
        phrase: PhrasePosition.empty,
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

    WordIndex currentSeekSegmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = sentence.getInsertionPositionInfo(readingSelectionCursor.insertionPosition);

    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return ReadingSelectionListCursor.defaultCursor(
        sentenceMap: sentenceMap,
        sentenceID: nextSentenceID,
        seekPosition: seekPosition,
      );
    }

    return this;
  }

  ReadingSelectionListCursor copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    SeekPosition? seekPosition,
    PhrasePosition? segmentRange,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return ReadingSelectionListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      phrase: segmentRange ?? readingSelectionCursor.phrase,
      insertionPosition: insertionPosition ?? readingSelectionCursor.insertionPosition,
      option: option ?? readingSelectionCursor.option,
    );
  }

  @override
  String toString() {
    return 'AnnotationSelectionListCursor(ID: ${sentenceID.id}, $readingSelectionCursor';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final ReadingSelectionListCursor otherSentenceSegments = other as ReadingSelectionListCursor;
    if (sentenceMap != otherSentenceSegments.sentenceMap) return false;
    if (sentenceID != otherSentenceSegments.sentenceID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (readingSelectionCursor != otherSentenceSegments.readingSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ readingSelectionCursor.hashCode;
}
