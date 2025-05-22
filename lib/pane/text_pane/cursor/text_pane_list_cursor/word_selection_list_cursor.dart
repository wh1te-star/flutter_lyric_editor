import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/sentence_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class SegmentSelectionListCursor extends TextPaneListCursor {
  late SegmentSelectionCursor segmentSelectionCursor;

  SegmentSelectionListCursor({
    required SentenceMap sentenceMap,
    required LyricSnippetID sentenceID,
    required SeekPosition seekPosition,
    required PhrasePosition segmentRange,
    required bool isRangeSelection,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");

    segmentSelectionCursor = SegmentSelectionCursor(
      lyricSnippet: sentenceMap[sentenceID]!,
      seekPosition: seekPosition,
      segmentRange: segmentRange,
      isRangeSelection: isRangeSelection,
    );
    textPaneCursor = segmentSelectionCursor;
  }

  bool isIDContained() {
    if (sentenceMap.isEmpty) {
      return true;
    }
    Sentence? lyricSnippet = sentenceMap[lyricSnippetID];
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
      sentenceMap: sentenceMap,
      sentenceID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: defaultCursor.segmentRange,
      isRangeSelection: defaultCursor.isRangeSelection,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    int index = sentenceMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = sentenceMap.keys.toList()[index - 1];
    return defaultCursor(nextLyricSnippetID);
  }

  @override
  TextPaneListCursor moveDownCursor() {
    int index = sentenceMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index + 1 >= sentenceMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = sentenceMap.keys.toList()[index + 1];
    return defaultCursor(nextLyricSnippetID);
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    SegmentSelectionCursor nextCursor = segmentSelectionCursor.moveLeftCursor() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    SegmentSelectionCursor nextCursor = segmentSelectionCursor.moveRightCursor() as SegmentSelectionCursor;
    return SegmentSelectionListCursor(
      sentenceMap: sentenceMap,
      sentenceID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isRangeSelection: nextCursor.isRangeSelection,
    );
  }

  TextPaneListCursor exitSegmentSelectionMode() {
    return SentenceSelectionListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: lyricSnippetID,
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
      sentenceMap: lyricSnippetMap,
      sentenceID: lyricSnippetID,
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
    PhrasePosition? segmentRange,
    bool? isRangeSelection,
  }) {
    return SegmentSelectionListCursor(
      sentenceMap: lyricSnippetMap ?? this.sentenceMap,
      sentenceID: lyricSnippetID ?? this.lyricSnippetID,
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
    if (sentenceMap != otherSentenceSegments.sentenceMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentSelectionCursor != otherSentenceSegments.segmentSelectionCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ segmentSelectionCursor.hashCode;
}
