import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSelectionCursor extends TextPaneCursor {
  InsertionPosition charPosition;
  Option option;

  SentenceSelectionCursor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.charPosition,
    this.option,
  );

  @override
    SentenceSelectionCursor moveUp(){
      
    }

  static SentenceSelectionCursor get empty => SentenceSelectionCursor(
        LyricSnippetID.empty,
        CursorBlinker.empty,
        InsertionPosition.empty,
        Option.former,
      );
  bool get isEmpty => this == empty;

  SentenceSegment copyWith({String? word, Duration? duration}) {
    return SentenceSegment(
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
    final SentenceSegment otherSentenceSegments = other as SentenceSegment;
    return word == otherSentenceSegments.word && duration == otherSentenceSegments.duration;
  }

  @override
  int get hashCode => word.hashCode ^ duration.hashCode;
}
