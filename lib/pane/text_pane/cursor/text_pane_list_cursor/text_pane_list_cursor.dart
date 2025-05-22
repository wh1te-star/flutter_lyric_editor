import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';

abstract class TextPaneListCursor {
  late TextPaneCursor textPaneCursor;
  SentenceMap lyricSnippetMap;
  LyricSnippetID lyricSnippetID;
  SeekPosition seekPosition;

  TextPaneListCursor(this.lyricSnippetMap, this.lyricSnippetID, this.seekPosition);

  TextPaneListCursor moveUpCursor();
  TextPaneListCursor moveDownCursor();
  TextPaneListCursor moveLeftCursor();
  TextPaneListCursor moveRightCursor();

  TextPaneListCursor updateCursor(
    SentenceMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  );
}
