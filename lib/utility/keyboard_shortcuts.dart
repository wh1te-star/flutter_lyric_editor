import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/pane/video_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/dialog/text_field_dialog.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet.dart';

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
              timingService.addSnippet("default sentence", musicPlayerProvider.seekPosition, timelinePaneProvider.selectingVocalist[0]);
            }
          }(),
        ),
        DeleteSnippetIntent: CallbackAction<DeleteSnippetIntent>(
          onInvoke: (DeleteSnippetIntent intent) => () {
            timingService.deleteSnippet(timelinePaneProvider.selectingSnippets[0]);
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
            SnippetID targetID = cursor.snippetID;
            LyricSnippet targetSnippet = timingService.getSnippetWithID(targetID);

            String annotationString = (await displayTextFieldDialog(context, [""]))[0];
            if (annotationString != "") {
              timingService.addAnnotation(targetID, annotationString, cursor.annotationSegmentRange.startIndex, textPaneProvider.cursor.annotationSegmentRange.endIndex);
            }

            textPaneProvider.cursor.isSegmentSelectionMode = false;
            textPaneProvider.cursor.isRangeSelection = false;
          }(),
        ),
        DeleteAnnotationIntent: CallbackAction<DeleteAnnotationIntent>(
          onInvoke: (DeleteAnnotationIntent intent) => () {
            TextPaneCursor cursor = textPaneProvider.cursor;
            if (cursor.isAnnotationSelection) {
              timingService.deleteAnnotation(cursor.snippetID, cursor.annotationSegmentRange);
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
            int seekPosition = musicPlayerProvider.seekPosition;
            timingService.addSection(seekPosition);
          }(),
        ),
        DeleteSectionIntent: CallbackAction<DeleteSectionIntent>(
          onInvoke: (DeleteSectionIntent intent) => () {
            int seekPosition = musicPlayerProvider.seekPosition;
            timingService.deleteSection(seekPosition);
          }(),
        ),
        TimingPointAddIntent: CallbackAction<TimingPointAddIntent>(
          onInvoke: (TimingPointAddIntent intent) => () {
            int seekPosition = musicPlayerProvider.seekPosition;
            TextPaneCursor cursor = textPaneProvider.cursor;
            if (!cursor.isAnnotationSelection) {
              timingService.addTimingPoint(
                snippetID: cursor.snippetID,
                charPosition: textPaneProvider.cursor.charPosition,
                seekPosition: seekPosition,
              );
            } else {
              timingService.addTimingPoint(
                snippetID: cursor.snippetID,
                annotationRange: cursor.annotationSegmentRange,
                charPosition: textPaneProvider.cursor.charPosition,
                seekPosition: seekPosition,
              );
            }
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSnippets) {
              TextPaneCursor cursor = textPaneProvider.cursor;
              if (!cursor.isAnnotationSelection) {
                timingService.deleteTimingPoint(
                  snippetID: id,
                  charPosition: cursor.charPosition,
                  option: cursor.option,
                );
              } else {
                timingService.deleteTimingPoint(
                  snippetID: id,
                  annotationRange: cursor.annotationSegmentRange,
                  charPosition: cursor.charPosition,
                  option: cursor.option,
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
            timingService.concatenateSnippets(timelinePaneProvider.selectingSnippets);
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
