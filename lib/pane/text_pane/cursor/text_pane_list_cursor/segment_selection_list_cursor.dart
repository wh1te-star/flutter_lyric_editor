import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/sentence_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';

class SegmentSelectionListCursor extends TextPaneListCursor {
  late SegmentSelectionCursor segmentSelectionCursor;

  SegmentSelectionListCursor({
    required SentenceMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required Phrase segmentRange,
    required bool isRangeSelection,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");

    segmentSelectionCursor = SegmentSelectionCursor(
      lyricSnippet: lyricSnippetMap[lyricSnippetID]!,
      seekPosition: seekPosition,
      segmentRange: segmentRange,
      isRangeSelection: isRangeSelection,
    );
    textPaneCursor = segmentSelectionCursor;
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

  SegmentSelectionListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final SegmentSelectionListCursor _empty = SegmentSelectionListCursor._privateConstructor(
    SentenceMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
  );
  static SegmentSelectionListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  SegmentSelectionListCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    SegmentSelectionCursor defaultCursor = segmentSelectionCursor.defaultCursor();
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: defaultCursor.segmentRange,
      isRangeSelection: defaultCursor.isRangeSelection,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return defaultCursor(nextLyricSnippetID);
  }

  @override
  TextPaneListCursor moveDownCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index + 1 >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    return defaultCursor(nextLyricSnippetID);
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    SegmentSelectionCursor nextCursor = segmentSelectionCursor.moveLeftCursor() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    SegmentSelectionCursor nextCursor = segmentSelectionCursor.moveRightCursor() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  TextPaneListCursor exitSegmentSelectionMode() {
    return SentenceSelectionListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  TextPaneListCursor switchToRangeSelection() {
    SegmentSelectionCursor nextCursor = segmentSelectionCursor.switchToRangeSelection() as SegmentSelectionCursor;
    return copyWith(segmentRange: nextCursor.segmentRange, isRangeSelection: nextCursor.isRangeSelection);
  }

  @override
  TextPaneListCursor updateCursor(
    SentenceMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: segmentSelectionCursor.segmentRange,
      isRangeSelection: segmentSelectionCursor.isRangeSelection,
    );
  }

  @override
  SegmentSelectionListCursor copyWith({
    SentenceMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    Phrase? segmentRange,
    bool? isRangeSelection,
  }) {
    return SegmentSelectionListCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? segmentSelectionCursor.segmentRange,
      isRangeSelection: isRangeSelection ?? segmentSelectionCursor.isRangeSelection,
    );
  }

  @override
  String toString() {
    return 'SegmentSelectionCursor(ID: ${lyricSnippetID.id}, segmentIndex: $segmentSelectionCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SegmentSelectionListCursor otherSentenceSegments = other as SegmentSelectionListCursor;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentSelectionCursor != otherSentenceSegments.segmentSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ segmentSelectionCursor.hashCode;
}
