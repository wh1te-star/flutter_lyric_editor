import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class WordListCursor extends TextPaneListCursor {
  late WordCursor wordCursor;

  WordListCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required SegmentRange segmentRange,
    required bool isExpandMode,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");

    wordCursor = WordCursor(
      lyricSnippet: lyricSnippetMap[lyricSnippetID]!,
      seekPosition: seekPosition,
      segmentRange: segmentRange,
      isExpandMode: isExpandMode,
    );
    textPaneCursor = wordCursor;
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

  WordListCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
  );
  static final WordListCursor _empty = WordListCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
  );
  static WordListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  WordListCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    WordCursor defaultCursor = wordCursor.defaultCursor();
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: defaultCursor.segmentRange,
      isExpandMode: defaultCursor.isExpandMode,
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
    WordCursor nextCursor = wordCursor.moveLeftCursor() as WordCursor;
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    WordCursor nextCursor = wordCursor.moveRightCursor() as WordCursor;
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextCursor.segmentRange,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  TextPaneListCursor exitWordMode() {
    return BaseListCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  TextPaneListCursor switchToExpandMode() {
    WordCursor nextCursor = wordCursor.switchToExpandMode() as WordCursor;
    return copyWith(segmentRange: nextCursor.segmentRange, isExpandMode: nextCursor.isExpandMode);
  }

  @override
  TextPaneListCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: wordCursor.segmentRange,
      isExpandMode: wordCursor.isExpandMode,
    );
  }

  @override
  WordListCursor copyWith({
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    SegmentRange? segmentRange,
    bool? isExpandMode,
  }) {
    return WordListCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? wordCursor.segmentRange,
      isExpandMode: isExpandMode ?? wordCursor.isExpandMode,
    );
  }

  @override
  String toString() {
    return 'WordCursor(ID: ${lyricSnippetID.id}, segmentIndex: $wordCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final WordListCursor otherSentenceSegments = other as WordListCursor;
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (wordCursor != otherSentenceSegments.wordCursor) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ wordCursor.hashCode;
}
