import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

abstract class TextPaneListCursor {
  late TextPaneCursor textPaneCursor;
  SentenceMap sentenceMap;
  SentenceID sentenceID;
  AbsoluteSeekPosition seekPosition;

  TextPaneListCursor(this.sentenceMap, this.sentenceID, this.seekPosition);

  TextPaneListCursor moveUpCursor();
  TextPaneListCursor moveDownCursor();
  TextPaneListCursor moveLeftCursor();
  TextPaneListCursor moveRightCursor();

  TextPaneListCursor updateCursor(
    SentenceMap sentenceMap,
    SentenceID sentenceID,
    AbsoluteSeekPosition seekPosition,
  );
}
