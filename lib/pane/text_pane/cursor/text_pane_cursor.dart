import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

abstract class TextPaneCursor {
  LyricSnippetID lyricSnippetID;
  CursorBlinker cursorBlinker;
  TextPaneCursor(this.lyricSnippetID, this.cursorBlinker);
  
  TextPaneCursor moveLeft();
  TextPaneCursor moveRight();
  TextPaneCursor moveUp();
  TextPaneCursor moveDown();
}

{
  void enterSegmentSelectionMode() {
    isSegmentSelectionMode = true;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  void exitSegmentSelectionMode() {
    isSegmentSelectionMode = false;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  bool isInRange(int index) {
    if (annotationSegmentRange.startIndex <= annotationSegmentRange.endIndex) {
      return annotationSegmentRange.startIndex <= index && index <= annotationSegmentRange.endIndex;
    } else {
      return annotationSegmentRange.endIndex <= index && index <= annotationSegmentRange.startIndex;
    }
  }

  TextPaneCursor copyWith({
    LyricSnippetID? snippetID,
    InsertionPosition? charPosition,
    Option? option,
    bool? isSegmentSelectionMode,
    bool? isRangeSelection,
    bool? isAnnotationSelection,
    SegmentRange? annotationSegmentRange,
  }) {
    return TextPaneCursor(
      snippetID ?? this.snippetID,
      charPosition ?? this.charPosition,
      option ?? this.option,
      isSegmentSelectionMode ?? this.isSegmentSelectionMode,
      isRangeSelection ?? this.isRangeSelection,
      isAnnotationSelection ?? this.isAnnotationSelection,
      annotationSegmentRange ?? this.annotationSegmentRange,
    );
  }

  @override
  String toString() {
    if (!isAnnotationSelection) {
      if (!isSegmentSelectionMode) {
        return "SnippetSelection-> snippetID: $snippetID, charPosition: $charPosition, option: $option";
      } else {
        return "SegmentSelection-> snippetID: $snippetID, segment range: $annotationSegmentRange";
      }
    } else {
      return "AnnotationSelection-> snippetID: $snippetID, annotationRange: $annotationSegmentRange, charPosition: $charPosition, option: $option";
    }
  }

  static TextPaneCursor get emptyValue {
    return TextPaneCursor(
      LyricSnippetID(0),
      InsertionPosition(0),
      Option.former,
      false,
      false,
      false,
      SegmentRange.empty,
    );
  }
}
