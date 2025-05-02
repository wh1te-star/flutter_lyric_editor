import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

abstract class TextPaneCursor {
  TextPaneCursor();

  TextPaneCursor defaultCursor(LyricSnippetID lyricSnippetID);
  TextPaneCursor moveUpCursor();
  TextPaneCursor moveDownCursor();
  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();
  TextPaneCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  );
}
