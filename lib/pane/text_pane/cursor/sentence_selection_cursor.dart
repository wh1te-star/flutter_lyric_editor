import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSelectionCursor extends TextPaneCursor {
  InsertionPosition charPosition;
  Option option;

  SentenceSelectionCursor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.cursorBlinker,
    this.charPosition,
    this.option,
  );

  SentenceSelectionCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.cursorBlinker,
    this.charPosition,
    this.option,
  );
  static final SentenceSelectionCursor _empty = SentenceSelectionCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    CursorBlinker.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static SentenceSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  SentenceSelectionCursor moveUp() {}

  SentenceSelectionCursor copyWith({
    String? word,
    Duration? duration,
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    CursorBlinker.empty,
    InsertionPosition.empty,
    Option.former,
  }) {
    return SentenceSelectionCursor(
      word ?? this.word,
      duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'SentenceSegment(wordLength: $word, wordDuration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionCursor otherSentenceSegments = other as SentenceSelectionCursor;
    return word == otherSentenceSegments.word && duration == otherSentenceSegments.duration;
  }

  @override
  int get hashCode => word.hashCode ^ duration.hashCode;
}
