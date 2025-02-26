import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';

abstract class LyricSnippetEdit<CursorType extends TextPaneCursor> extends StatelessWidget {
  static const String annotationEdgeChar = '🔷';
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final CursorType textPaneCursor;

  const LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursor, {super.key});
}
