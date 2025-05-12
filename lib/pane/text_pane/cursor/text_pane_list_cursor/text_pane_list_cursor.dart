import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/position/seek_position.dart';

abstract class TextPaneListCursor {
  LyricSnippetMap lyricSnippetMap;
  LyricSnippetID lyricSnippetID;
  SeekPosition seekPosition;

  TextPaneListCursor(this.lyricSnippetMap, this.lyricSnippetID, this.seekPosition);

  TextPaneListCursor moveUpCursor();
  TextPaneListCursor moveDownCursor();
  TextPaneListCursor moveLeftCursor();
  TextPaneListCursor moveRightCursor();

  TextPaneListCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  );
}
