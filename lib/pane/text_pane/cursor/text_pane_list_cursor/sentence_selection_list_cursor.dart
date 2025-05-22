import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/annotation_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/segment_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';

class SentenceSelectionListCursor extends TextPaneListCursor {
  late SentenceSelectionCursor sentenceSelectionCursor;
  SentenceSelectionListCursor({
    required SentenceMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");

    Sentence lyricSnippet = lyricSnippetMap.containsKey(lyricSnippetID) ? lyricSnippetMap[lyricSnippetID]! : Sentence.empty;
    sentenceSelectionCursor = SentenceSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: option,
    );
    textPaneCursor = sentenceSelectionCursor;
  }

  bool isIDContained() {
    if (lyricSnippetMap.isEmpty) {
      return true;
    }
    Sentence? lyricSnippet = lyricSnippetMap[lyricSnippetID];
    if (lyricSnippet == null) {
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
    LyricSnippetID.empty,
    SeekPosition.empty,
  );
  static SentenceSelectionListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory SentenceSelectionListCursor.defaultCursor({
    required SentenceMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
  }) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionListCursor(
        lyricSnippetMap: SentenceMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: SeekPosition.empty,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }
    Sentence lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    WordIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = lyricSnippet.timeline.leftTiming(segmentIndex).insertionPosition + 1;
    return SentenceSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    Sentence lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    Phrase annotationIndex = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return SentenceSelectionListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveDownCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    Sentence nextLyricSnippet = lyricSnippetMap[nextLyricSnippetID]!;

    Phrase annotationIndex = nextLyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    SentenceSelectionCursor nextCursor = sentenceSelectionCursor.moveLeftCursor() as SentenceSelectionCursor;
    return SentenceSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    SentenceSelectionCursor nextCursor = sentenceSelectionCursor.moveRightCursor() as SentenceSelectionCursor;
    return SentenceSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor updateCursor(
    SentenceMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionListCursor(
        lyricSnippetMap: SentenceMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: seekPosition,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    if (!lyricSnippetMap.containsKey(lyricSnippetID)) {
      lyricSnippetID = lyricSnippetMap.keys.first;
    }
    Sentence lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    WordIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo(sentenceSelectionCursor.insertionPosition);
    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return SentenceSelectionListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: sentenceSelectionCursor.insertionPosition,
      option: sentenceSelectionCursor.option,
    );
  }

  TextPaneListCursor enterSegmentSelectionMode() {
    SegmentSelectionCursor nextCursor = sentenceSelectionCursor.enterSegmentSelectionMode() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  SentenceSelectionListCursor copyWith({
    SentenceMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return SentenceSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? sentenceSelectionCursor.insertionPosition,
      option: option ?? sentenceSelectionCursor.option,
    );
  }

  @override
  String toString() {
    return 'SentenceSelectionCursor(ID: ${lyricSnippetID.id}, position: $sentenceSelectionCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionListCursor otherSentenceSegments = other as SentenceSelectionListCursor;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (sentenceSelectionCursor != otherSentenceSegments.sentenceSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ sentenceSelectionCursor.hashCode;
}
