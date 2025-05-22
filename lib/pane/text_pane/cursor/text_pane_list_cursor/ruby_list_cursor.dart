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

class AnnotationSelectionListCursor extends TextPaneListCursor {
  late AnnotationSelectionCursor annotationSelectionCursor;

  AnnotationSelectionListCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required SegmentRange segmentRange,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
    assert(doesSeekPositionPointAnnotation(), "The passed seek position does not point to any annotation.");
    annotationSelectionCursor = AnnotationSelectionCursor(
      lyricSnippet: lyricSnippetMap[lyricSnippetID]!,
      seekPosition: seekPosition,
      segmentRange: segmentRange,
      insertionPosition: insertionPosition,
      option: option,
    );
    textPaneCursor = annotationSelectionCursor;
  }

  bool isIDContained() {
    if (lyricSnippetMap.isEmpty) {
      return true;
    }
    LyricSnippet? lyricSnippet = lyricSnippetMap[lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  AnnotationSelectionListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final AnnotationSelectionListCursor _empty = AnnotationSelectionListCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
  );
  static AnnotationSelectionListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  bool doesSeekPositionPointAnnotation() {
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    return annotationSegmentRange.isNotEmpty;
  }

  factory AnnotationSelectionListCursor.defaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
  }) {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    Annotation annotation = lyricSnippet.annotationMap[annotationSegmentRange]!;
    SentenceSegmentIndex segmentIndex = annotation.getSegmentIndexFromSeekPosition(seekPosition);

    return AnnotationSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: annotationSegmentRange,
      insertionPosition: annotation.timing.leftTimingPoint(segmentIndex).insertionPosition + 1,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });

    int nextIndex = index - 1;
    if (nextIndex < 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[nextIndex];
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

    int nextIndex = index + 1;
    if (nextIndex >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[nextIndex];
    return SentenceSelectionListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
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
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    if (lyricSnippetMap.isEmpty) {
      return AnnotationSelectionListCursor(
        lyricSnippetMap: LyricSnippetMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: seekPosition,
        segmentRange: SegmentRange.empty,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.first;
    LyricSnippet lyricSnippet = lyricSnippetMap.values.first;
    if (lyricSnippetMap.containsKey(nextLyricSnippetID)) {
      nextLyricSnippetID = lyricSnippetID;
      lyricSnippet = lyricSnippetMap[nextLyricSnippetID]!;
    }

    SentenceSegmentIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo(annotationSelectionCursor.insertionPosition);

    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return AnnotationSelectionListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: nextLyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return this;
  }

  AnnotationSelectionListCursor copyWith({
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    SegmentRange? segmentRange,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return AnnotationSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? annotationSelectionCursor.segmentRange,
      insertionPosition: insertionPosition ?? annotationSelectionCursor.insertionPosition,
      option: option ?? annotationSelectionCursor.option,
    );
  }

  @override
  String toString() {
    return 'AnnotationSelectionListCursor(ID: ${lyricSnippetID.id}, $annotationSelectionCursor';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final AnnotationSelectionListCursor otherSentenceSegments = other as AnnotationSelectionListCursor;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (annotationSelectionCursor != otherSentenceSegments.annotationSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ annotationSelectionCursor.hashCode;
}
