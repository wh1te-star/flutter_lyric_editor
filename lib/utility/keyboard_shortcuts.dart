import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/pane/text_pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/pane/video_pane/video_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/dialog/text_field_dialog.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';

final keyboardShortcutsMasterProvider = ChangeNotifierProvider((ref) => KeyboardShortcutsNotifier());

class KeyboardShortcutsNotifier with ChangeNotifier {
  bool _enable = true;

  bool get enable => _enable;

  void setEnable(bool value) {
    _enable = value;
    notifyListeners();
  }

  KeyboardShortcutsNotifier();
}

class KeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  _KeyboardShortcutsState createState() => _KeyboardShortcutsState(child: child, videoPaneFocusNode: videoPaneFocusNode, textPaneFocusNode: textPaneFocusNode, timelinePaneFocusNode: timelinePaneFocusNode);
}

class _KeyboardShortcutsState extends ConsumerState<KeyboardShortcuts> {
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  late final MusicPlayerService musicPlayerProvider = ref.watch(musicPlayerMasterProvider.notifier);
  late final TimingService timingService = ref.watch(timingMasterProvider.notifier);
  late final TextPaneProvider textPaneProvider = ref.watch(textPaneMasterProvider.notifier);
  late final TimelinePaneProvider timelinePaneProvider = ref.watch(timelinePaneMasterProvider.notifier);
  late final VideoPaneProvider videoPaneProvider = ref.watch(videoPaneMasterProvider.notifier);

  bool enable = true;

  _KeyboardShortcutsState({
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  void initState() {
    super.initState();
  }

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyN): RewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM): ForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): AddSnippetIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA): EnterSegmentSelectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): DeleteSnippetIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): DeleteAnnotationIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): SnippetStartMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): textPaneProvider.cursor.isSegmentSelectionMode ? SegmentRangeSelectIntent() : SnippetEndMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): SpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): SpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyI): TimingPointAddIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyO): TimingPointDeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyZ): SnippetDivideIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyX): SnippetConcatenateIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyU): UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): TextPaneCursorMoveLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): TextPaneCursorMoveDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyK): TextPaneCursorMoveUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyL): TextPaneCursorMoveRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG): TimelineCursorMoveLeft(),
        LogicalKeySet(LogicalKeyboardKey.keyF): TimelineCursorMoveDown(),
        LogicalKeySet(LogicalKeyboardKey.keyD): TimelineCursorMoveUp(),
        LogicalKeySet(LogicalKeyboardKey.keyS): TimelineCursorMoveRight(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): TimelineZoomInIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyJ): TimelineZoomOutIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE): AddSectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR): DeleteSectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD): DisplayModeSwitchIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): AddAnnotationIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): CancelIntent(),
      };

  Map<Type, Action<Intent>> get actions => {
        PlayPauseIntent: CallbackAction<PlayPauseIntent>(
          onInvoke: (PlayPauseIntent intent) => () {
            musicPlayerProvider.playPause();
          }(),
        ),
        RewindIntent: CallbackAction<RewindIntent>(
          onInvoke: (RewindIntent intent) => () {
            musicPlayerProvider.rewind(1000);
          }(),
        ),
        ForwardIntent: CallbackAction<ForwardIntent>(
          onInvoke: (ForwardIntent intent) => () {
            musicPlayerProvider.forward(1000);
          }(),
        ),
        AddSnippetIntent: CallbackAction<AddSnippetIntent>(
          onInvoke: (AddSnippetIntent intent) => () {
            if (timelinePaneProvider.selectingVocalist.isNotEmpty) {
              Timing timing = Timing(
                startTimestamp: musicPlayerProvider.seekPosition,
                sentenceSegmentList: SentenceSegmentList([
                  SentenceSegment("default sentence", Duration(milliseconds: 3000)),
                ]),
              );
              LyricSnippet lyricSnippet = LyricSnippet(
                vocalistID: timelinePaneProvider.selectingVocalist[0],
                timing: timing,
                annotationMap: AnnotationMap.empty,
              );
              timingService.addLyricSnippet(lyricSnippet);
            }
          }(),
        ),
        DeleteSnippetIntent: CallbackAction<DeleteSnippetIntent>(
          onInvoke: (DeleteSnippetIntent intent) => () {
            timingService.removeLyricSnippet(timelinePaneProvider.selectingSnippets[0]);
          }(),
        ),
        EnterSegmentSelectionIntent: CallbackAction<EnterSegmentSelectionIntent>(
          onInvoke: (EnterSegmentSelectionIntent intent) => () {
            TextPaneCursor cursor = textPaneProvider.cursor;
            if (!cursor.isAnnotationSelection) {
              cursor.enterSegmentSelectionMode();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You cannot add an annotation to an annotation."),
                ),
              );
            }
            setState(() {});
          }(),
        ),
        SegmentRangeSelectIntent: CallbackAction<SegmentRangeSelectIntent>(
          onInvoke: (SegmentRangeSelectIntent intent) => () {
            textPaneProvider.cursor.isRangeSelection = true;
            setState(() {});
          }(),
        ),
        AddAnnotationIntent: CallbackAction<AddAnnotationIntent>(
          onInvoke: (AddAnnotationIntent intent) => () async {
            TextPaneCursor cursor = textPaneProvider.cursor;
            LyricSnippetID targetID = cursor.lyricSnippetID;
            LyricSnippet targetSnippet = timingService.getLyricSnippetByID(targetID);

            String annotationString = (await displayTextFieldDialog(context, [""]))[0];
            if (annotationString != "") {
              int startIndex = cursor.annotationSegmentRange.startIndex;
              int endIndex = textPaneProvider.cursor.annotationSegmentRange.endIndex;
              timingService.addAnnotation(targetID, SegmentRange(startIndex, endIndex), annotationString);
            }

            textPaneProvider.cursor.isSegmentSelectionMode = false;
            textPaneProvider.cursor.isRangeSelection = false;
          }(),
        ),
        DeleteAnnotationIntent: CallbackAction<DeleteAnnotationIntent>(
          onInvoke: (DeleteAnnotationIntent intent) => () {
            TextPaneCursor cursor = textPaneProvider.cursor;
            if (cursor.isAnnotationSelection) {
              timingService.removeAnnotation(cursor.lyricSnippetID, cursor.annotationSegmentRange);
            }
          }(),
        ),
        SnippetStartMoveIntent: CallbackAction<SnippetStartMoveIntent>(
          onInvoke: (SnippetStartMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSnippets) {
              timingService.manipulateSnippet(id, SnippetEdge.start, false);
            }
          }(),
        ),
        SnippetEndMoveIntent: CallbackAction<SnippetEndMoveIntent>(
          onInvoke: (SnippetEndMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSnippets) {
              timingService.manipulateSnippet(id, SnippetEdge.end, false);
            }
          }(),
        ),
        VolumeUpIntent: CallbackAction<VolumeUpIntent>(
          onInvoke: (VolumeUpIntent intent) => () {
            musicPlayerProvider.volumeUp(0.1);
          }(),
        ),
        VolumeDownIntent: CallbackAction<VolumeDownIntent>(
          onInvoke: (VolumeDownIntent intent) => () {
            musicPlayerProvider.volumeDown(0.1);
          }(),
        ),
        SpeedUpIntent: CallbackAction<SpeedUpIntent>(
          onInvoke: (SpeedUpIntent intent) => () {
            musicPlayerProvider.speedUp(0.1);
          }(),
        ),
        SpeedDownIntent: CallbackAction<SpeedDownIntent>(
          onInvoke: (SpeedDownIntent intent) => () {
            musicPlayerProvider.speedDown(0.1);
          }(),
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (UndoIntent intent) => () {
            timingService.undo();
          }(),
        ),
        TextPaneCursorMoveLeftIntent: CallbackAction<TextPaneCursorMoveLeftIntent>(
          onInvoke: (TextPaneCursorMoveLeftIntent intent) => () {
            textPaneProvider.moveLeftCursor();
          }(),
        ),
        TextPaneCursorMoveDownIntent: CallbackAction<TextPaneCursorMoveDownIntent>(
          onInvoke: (TextPaneCursorMoveDownIntent intent) => () {
            textPaneProvider.moveDownCursor();
          }(),
        ),
        TextPaneCursorMoveUpIntent: CallbackAction<TextPaneCursorMoveUpIntent>(
          onInvoke: (TextPaneCursorMoveUpIntent intent) => () {
            textPaneProvider.moveUpCursor();
          }(),
        ),
        TextPaneCursorMoveRightIntent: CallbackAction<TextPaneCursorMoveRightIntent>(
          onInvoke: (TextPaneCursorMoveRightIntent intent) => () {
            textPaneProvider.moveRightCursor();
          }(),
        ),
        TimelineZoomInIntent: CallbackAction<TimelineZoomInIntent>(
          onInvoke: (TimelineZoomInIntent intent) => () {
            timelinePaneProvider.zoomIn();
          }(),
        ),
        TimelineZoomOutIntent: CallbackAction<TimelineZoomOutIntent>(
          onInvoke: (TimelineZoomOutIntent intent) => () {
            timelinePaneProvider.zoomOut();
          }(),
        ),
        AddSectionIntent: CallbackAction<AddSectionIntent>(
          onInvoke: (AddSectionIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            timingService.addSection(seekPosition);
          }(),
        ),
        DeleteSectionIntent: CallbackAction<DeleteSectionIntent>(
          onInvoke: (DeleteSectionIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            timingService.removeSection(seekPosition);
          }(),
        ),
        TimingPointAddIntent: CallbackAction<TimingPointAddIntent>(
          onInvoke: (TimingPointAddIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            TextPaneCursor cursor = textPaneProvider.cursor;
            if (!cursor.isAnnotationSelection) {
              timingService.addTimingPoint(
                cursor.lyricSnippetID,
                textPaneProvider.cursor.charPosition,
                seekPosition,
              );
            } else {
              timingService.addAnnotationTimingPoint(
                cursor.lyricSnippetID,
                cursor.annotationSegmentRange,
                textPaneProvider.cursor.charPosition,
                seekPosition,
              );
            }
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSnippets) {
              TextPaneCursor cursor = textPaneProvider.cursor;
              if (!cursor.isAnnotationSelection) {
                timingService.removeTimingPoint(
                  id,
                  cursor.charPosition,
                  cursor.option,
                );
              } else {
                timingService.removeAnnotationTimingPoint(
                  id,
                  cursor.annotationSegmentRange,
                  cursor.charPosition,
                  cursor.option,
                );
              }
            }
          }(),
        ),
        SnippetDivideIntent: CallbackAction<SnippetDivideIntent>(
          onInvoke: (SnippetDivideIntent intent) => () {
            timingService.divideSnippet(timelinePaneProvider.selectingSnippets[0], textPaneProvider.cursor.charPosition, musicPlayerProvider.seekPosition);
          }(),
        ),
        SnippetConcatenateIntent: CallbackAction<SnippetConcatenateIntent>(
          onInvoke: (SnippetConcatenateIntent intent) => () {
            final List<LyricSnippetID> selectingSnippets = timelinePaneProvider.selectingSnippets;
            if (selectingSnippets.length >= 2) {
              timingService.concatenateSnippets(selectingSnippets[0], selectingSnippets[1]);
            }
          }(),
        ),
        DisplayModeSwitchIntent: CallbackAction<DisplayModeSwitchIntent>(
          onInvoke: (DisplayModeSwitchIntent intent) => () {
            videoPaneProvider.switchDisplayMode();
          }(),
        ),
        TimelineCursorMoveLeft: CallbackAction<TimelineCursorMoveLeft>(
          onInvoke: (TimelineCursorMoveLeft intent) => () {
            timelinePaneProvider.moveLeftCursor();
          }(),
        ),
        TimelineCursorMoveDown: CallbackAction<TimelineCursorMoveDown>(
          onInvoke: (TimelineCursorMoveDown intent) => () {
            timelinePaneProvider.moveDownCursor();
          }(),
        ),
        TimelineCursorMoveUp: CallbackAction<TimelineCursorMoveUp>(
          onInvoke: (TimelineCursorMoveUp intent) => () {
            timelinePaneProvider.moveUpCursor();
          }(),
        ),
        TimelineCursorMoveRight: CallbackAction<TimelineCursorMoveRight>(
          onInvoke: (TimelineCursorMoveRight intent) => () {
            timelinePaneProvider.moveRightCursor();
          }(),
        ),
        CancelIntent: CallbackAction<CancelIntent>(
          onInvoke: (CancelIntent intent) => () {
            if (textPaneProvider.cursor.isSegmentSelectionMode) {
              textPaneProvider.cursor.exitSegmentSelectionMode();
            }
          }(),
        ),
      };

  @override
  Widget build(BuildContext context) {
    if (enable) {
      return Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: actions,
          child: child,
        ),
      );
    } else {
      return Shortcuts(
        shortcuts: const <LogicalKeySet, Intent>{},
        child: Actions(
          actions: const <Type, Action<Intent>>{},
          child: child,
        ),
      );
    }
  }
}

class PlayPauseIntent extends Intent {}

class ForwardIntent extends Intent {}

class RewindIntent extends Intent {}

class AddSnippetIntent extends Intent {}

class DeleteSnippetIntent extends Intent {}

class AddAnnotationIntent extends Intent {}

class DeleteAnnotationIntent extends Intent {}

class SnippetStartMoveIntent extends Intent {}

class SnippetEndMoveIntent extends Intent {}

class VolumeUpIntent extends Intent {}

class VolumeDownIntent extends Intent {}

class SpeedUpIntent extends Intent {}

class SpeedDownIntent extends Intent {}

class UndoIntent extends Intent {}

class TextPaneCursorMoveDownIntent extends Intent {}

class TextPaneCursorMoveUpIntent extends Intent {}

class TextPaneCursorMoveLeftIntent extends Intent {}

class TextPaneCursorMoveRightIntent extends Intent {}

class TimelineZoomInIntent extends Intent {}

class TimelineZoomOutIntent extends Intent {}

class EnterSegmentSelectionIntent extends Intent {}

class SegmentRangeSelectIntent extends Intent {}

class AddSectionIntent extends Intent {}

class DeleteSectionIntent extends Intent {}

class TimingPointAddIntent extends Intent {}

class TimingPointDeleteIntent extends Intent {}

class SnippetDivideIntent extends Intent {}

class SnippetConcatenateIntent extends Intent {}

class DisplayModeSwitchIntent extends Intent {}

class TimelineCursorMoveLeft extends Intent {}

class TimelineCursorMoveDown extends Intent {}

class TimelineCursorMoveUp extends Intent {}

class TimelineCursorMoveRight extends Intent {}

class CancelIntent extends Intent {}
