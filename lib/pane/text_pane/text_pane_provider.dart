import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

final textPaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TextPaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TextPaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;
  late TextPaneCursor textPaneCursor;
  late CursorBlinker cursorBlinker;

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      //updateCursorIfNeedBySeekPosition();
    });

    timingService.addListener(() {
      //updateCursorIfNeedByItemDeletion();
    });

    cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {
        notifyListeners();
      },
    );
    textPaneCursor = TextPaneCursor(LyricSnippetID.empty, cursorBlinker);
  }

  /*
  void updateCursorIfNeedBySeekPosition() {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    if (!currentSnippets.keys.toList().contains(cursor.lyricSnippetID)) {
      cursor.lyricSnippetID = currentSnippets.keys.first;
    }

    LyricSnippet snippet = currentSnippets.values.first;
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.timing.getPositionTypeInfo(cursor.charPosition.position);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      cursor = getDefaultCursor(cursor.lyricSnippetID);
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    LyricSnippet? snippet = timingService.lyricSnippetMap[cursor.lyricSnippetID];
    if (snippet == null) {
      cursor = getDefaultCursor(LyricSnippetID(1));
      return;
    }

    if (!cursor.isAnnotationSelection) {
      return;
    }

    Annotation? annotation = snippet.annotationMap.map[cursor.annotationSegmentRange];
    if (annotation == null) {
      cursor = getDefaultCursor(cursor.lyricSnippetID);
      return;
    }
  }

  TextPaneCursor getDefaultCursor(LyricSnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;
    defaultCursor.isAnnotationSelection = false;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.lyricSnippetID = id;
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  TextPaneCursor getDefaultCursorOfAnnotation(LyricSnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;

    defaultCursor.isAnnotationSelection = true;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int? annotationIndex = snippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    MapEntry<SegmentRange, Annotation>? cursorAnnotationEntry = snippet.getAnnotationWords(annotationIndex!);
    SegmentRange range = cursorAnnotationEntry.key;
    Annotation annotation = cursorAnnotationEntry.value;

    int index = annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);

    defaultCursor.lyricSnippetID = id;
    defaultCursor.annotationSegmentRange = range;
    defaultCursor.charPosition = annotation.timingPoints[index].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  void moveUpCursor() {
    if (!cursor.isSegmentSelectionMode) {
      Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
      LyricSnippet cursorSnippet = timingService.lyricSnippetMap[cursor.lyricSnippetID]!;

      int? annotationIndex = cursorSnippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);

      if (cursor.isAnnotationSelection || annotationIndex == null) {
        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.lyricSnippetID);
        if (index > 0) {
          LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index - 1];
          cursor = getDefaultCursor(nextSnippetID);
        }
      } else {
        cursor = getDefaultCursorOfAnnotation(cursor.lyricSnippetID);
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveDownCursor() {
    if (!cursor.isSegmentSelectionMode) {
      if (cursor.isAnnotationSelection) {
        cursor = getDefaultCursor(cursor.lyricSnippetID);
      } else {
        Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;

        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.lyricSnippetID);
        if (index != -1 && index + 1 < currentSnippets.length) {
          LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index + 1];
          LyricSnippet nextSnippet = currentSnippets.values.toList()[index + 1];

          int? annotationIndex = nextSnippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
          if (annotationIndex == null) {
            cursor = getDefaultCursor(nextSnippetID);
          } else {
            cursor = getDefaultCursorOfAnnotation(nextSnippetID);
          }
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetMap.containsKey(cursor.lyricSnippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[cursor.lyricSnippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      Timing object = !cursor.isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = object.getPositionTypeInfo(cursor.charPosition.position);
      int seekPositionInfo = object.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.latter) {
        cursor.option = Option.former;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
        if (cursor.charPosition.position - 1 > 0) {
          cursor.charPosition--;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      } else {
        if (object.timingPoints[charPositionIndex - 1].charPosition.position > 0) {
          cursor.charPosition = object.timingPoints[charPositionIndex - 1].charPosition;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex - 1;
        if (nextSegmentIndex >= 0) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex - 1;
        if (nextSegmentIndex >= cursor.annotationSegmentRange.startIndex) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetMap.containsKey(cursor.lyricSnippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[cursor.lyricSnippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      Timing timing = !cursor.isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = timing.getPositionTypeInfo(cursor.charPosition.position);
      int seekPositionInfo = timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.former) {
        cursor.option = Option.latter;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
        if (cursor.charPosition.position + 1 < timing.sentence.length) {
          cursor.charPosition++;
          cursor.option = Option.former;
        }
      } else {
        if (timing.timingPoints[charPositionIndex + 1].charPosition.position < timing.sentence.length) {
          cursor.charPosition = timing.timingPoints[charPositionIndex + 1].charPosition;
          cursor.option = Option.former;
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex + 1;
        if (nextSegmentIndex <= snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }
  */
}
