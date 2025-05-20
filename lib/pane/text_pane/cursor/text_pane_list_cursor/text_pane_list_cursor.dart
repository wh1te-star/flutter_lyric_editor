import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';

abstract class TextPaneCursor {
  LyricSnippetMap lyricSnippetMap;
  LyricSnippetID lyricSnippetID;
  SeekPosition seekPosition;

  TextPaneCursor(this.lyricSnippetMap, this.lyricSnippetID, this.seekPosition);

  TextPaneCursor moveUpCursor();
  TextPaneCursor moveDownCursor();
  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  TextPaneCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  );
}
