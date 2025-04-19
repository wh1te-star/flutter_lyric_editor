import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

abstract class TextPaneCursorMover {
  final LyricSnippetMap lyricSnippetMap;
  final TextPaneCursor textPaneCursor;
  final CursorBlinker cursorBlinker;
  final SeekPosition seekPosition;

  TextPaneCursorMover({
    required this.lyricSnippetMap,
    required this.textPaneCursor,
    required this.cursorBlinker,
    required this.seekPosition,
  });

  TextPaneCursor defaultCursor(LyricSnippetID lyricSnippetID);
  TextPaneCursorMover moveUpCursor();
  TextPaneCursorMover moveDownCursor();
  TextPaneCursorMover moveLeftCursor();
  TextPaneCursorMover moveRightCursor();
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  );
}