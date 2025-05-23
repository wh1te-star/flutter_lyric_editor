import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/ruby_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

class BaseListCursor extends TextPaneListCursor {
  late BaseCursor baseCursor;
  BaseListCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required InsertionPosition insertionPosition,
    required Option option,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");

    LyricSnippet lyricSnippet = lyricSnippetMap.containsKey(lyricSnippetID) ? lyricSnippetMap[lyricSnippetID]! : LyricSnippet.empty;
    baseCursor = BaseCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: option,
    );
    textPaneCursor = baseCursor;
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

  BaseListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final BaseListCursor _empty = BaseListCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
  );
  static BaseListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseListCursor.defaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
  }) {
    if (lyricSnippetMap.isEmpty) {
      return BaseListCursor(
        lyricSnippetMap: LyricSnippetMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: SeekPosition.empty,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = lyricSnippet.timing.leftTimingPoint(segmentIndex).insertionPosition + 1;
    return BaseListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    SegmentRange annotationIndex = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return RubyListCursor.defaultCursor(
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
    return BaseListCursor.defaultCursor(
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
    LyricSnippet nextLyricSnippet = lyricSnippetMap[nextLyricSnippetID]!;

    SegmentRange annotationIndex = nextLyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return RubyListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return BaseListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    BaseCursor nextCursor = baseCursor.moveLeftCursor() as BaseCursor;
    return BaseListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    BaseCursor nextCursor = baseCursor.moveRightCursor() as BaseCursor;
    return BaseListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: nextCursor.insertionPosition,
      option: nextCursor.option,
    );
  }

  @override
  TextPaneListCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    if (lyricSnippetMap.isEmpty) {
      return BaseListCursor(
        lyricSnippetMap: LyricSnippetMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: seekPosition,
        insertionPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    if (!lyricSnippetMap.containsKey(lyricSnippetID)) {
      lyricSnippetID = lyricSnippetMap.keys.first;
    }
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    SentenceSegmentIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo(baseCursor.insertionPosition);
    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return BaseListCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return BaseListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      insertionPosition: baseCursor.insertionPosition,
      option: baseCursor.option,
    );
  }

  TextPaneListCursor enterWordMode() {
    WordCursor nextCursor = baseCursor.enterWordMode() as WordCursor;
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  BaseListCursor copyWith({
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return BaseListCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? baseCursor.insertionPosition,
      option: option ?? baseCursor.option,
    );
  }

  @override
  String toString() {
    return 'BaseListCursor(ID: ${lyricSnippetID.id}, position: $baseCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseListCursor otherSentenceSegments = other as BaseListCursor;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (baseCursor != otherSentenceSegments.baseCursor) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ baseCursor.hashCode;
}
