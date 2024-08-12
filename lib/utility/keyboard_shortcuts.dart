import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/pane/video_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final BuildContext context;
  final Widget child;

  KeyboardShortcuts({required this.context, required this.child});

  @override
  _KeyboardShortcutsState createState() => _KeyboardShortcutsState(context: context, child: this.child);
}

class _KeyboardShortcutsState extends ConsumerState<KeyboardShortcuts> {
  final BuildContext context;
  final Widget child;
  late final keyboardShortcutsProvider = ref.watch(keyboardShortcutsMasterProvider);
  late final musicPlayerProvider = ref.watch(musicPlayerMasterProvider.notifier);
  late final timingProvider = ref.watch(timingMasterProvider);
  late final textPaneProvider = ref.watch(textPaneMasterProvider);
  late final timelinePaneProvider = ref.watch(timelinePaneMasterProvider);
  late final videoPaneProvider = ref.watch(videoPaneMasterProvider);

  _KeyboardShortcutsState({required this.context, required this.child});

  @override
  void initState() {
    super.initState();
  }

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyN): RewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM): ForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): SnippetStartMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): SnippetEndMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): SpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): SpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyU): UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): TextPaneCursorMoveLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): TextPaneCursorMoveDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyK): TextPaneCursorMoveUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyL): TextPaneCursorMoveRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): TimelineZoomIn(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyJ): TimelineZoomOut(),
        LogicalKeySet(LogicalKeyboardKey.keyI): TimingPointAddIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyO): TimingPointDeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyZ): SnippetDivideIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyX): SnippetConcatenateIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD): DisplayModeSwitchIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG): TimelineCursorMoveLeft(),
        LogicalKeySet(LogicalKeyboardKey.keyF): TimelineCursorMoveDown(),
        LogicalKeySet(LogicalKeyboardKey.keyD): TimelineCursorMoveUp(),
        LogicalKeySet(LogicalKeyboardKey.keyS): TimelineCursorMoveRight(),
      };

  Map<Type, Action<Intent>> get actions => {
        PlayPauseIntent: CallbackAction<PlayPauseIntent>(
          onInvoke: (PlayPauseIntent intent) => () {
            musicPlayerProvider.requestPlayPause();
          }(),
        ),
        RewindIntent: CallbackAction<RewindIntent>(
          onInvoke: (RewindIntent intent) => () {
            musicPlayerProvider.requestRewind(1000);
          }(),
        ),
        ForwardIntent: CallbackAction<ForwardIntent>(
          onInvoke: (ForwardIntent intent) => () {
            musicPlayerProvider.requestForward(1000);
          }(),
        ),
        SnippetStartMoveIntent: CallbackAction<SnippetStartMoveIntent>(
          onInvoke: (SnippetStartMoveIntent intent) => () {
            List<LyricSnippetID> selectingSnippetIDs = timelinePaneProvider.selectingSnippet;
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              timingProvider.requestSnippetMove(id, SnippetEdge.start, true);
            });
          }(),
        ),
        SnippetEndMoveIntent: CallbackAction<SnippetEndMoveIntent>(
          onInvoke: (SnippetEndMoveIntent intent) => () {
            List<LyricSnippetID> selectingSnippetIDs = timelinePaneProvider.selectingSnippet;
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              timingProvider.requestSnippetMove(id, SnippetEdge.end, false);
            });
          }(),
        ),
        VolumeUpIntent: CallbackAction<VolumeUpIntent>(
          onInvoke: (VolumeUpIntent intent) => () {
            musicPlayerProvider.requestVolumeUp(0.1);
          }(),
        ),
        VolumeDownIntent: CallbackAction<VolumeDownIntent>(
          onInvoke: (VolumeDownIntent intent) => () {
            musicPlayerProvider.requestVolumeDown(0.1);
          }(),
        ),
        SpeedUpIntent: CallbackAction<SpeedUpIntent>(
          onInvoke: (SpeedUpIntent intent) => () {
            musicPlayerProvider.requestSpeedUp(0.1);
          }(),
        ),
        SpeedDownIntent: CallbackAction<SpeedDownIntent>(
          onInvoke: (SpeedDownIntent intent) => () {
            musicPlayerProvider.requestSpeedDown(0.1);
          }(),
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (UndoIntent intent) => () {
            timingProvider.requestUndo();
          }(),
        ),
        TextPaneCursorMoveLeftIntent: CallbackAction<TextPaneCursorMoveLeftIntent>(
          onInvoke: (TextPaneCursorMoveLeftIntent intent) => () {
            textPaneProvider.requestMoveLeftCharCursor();
          }(),
        ),
        TextPaneCursorMoveDownIntent: CallbackAction<TextPaneCursorMoveDownIntent>(
          onInvoke: (TextPaneCursorMoveDownIntent intent) => () {
            textPaneProvider.requestMoveDownCharCursor();
          }(),
        ),
        TextPaneCursorMoveUpIntent: CallbackAction<TextPaneCursorMoveUpIntent>(
          onInvoke: (TextPaneCursorMoveUpIntent intent) => () {
            textPaneProvider.requestMoveUpCharCursor();
          }(),
        ),
        TextPaneCursorMoveRightIntent: CallbackAction<TextPaneCursorMoveRightIntent>(
          onInvoke: (TextPaneCursorMoveRightIntent intent) => () {
            textPaneProvider.requestMoveRightCharCursor();
          }(),
        ),
        TimelineZoomIn: CallbackAction<TimelineZoomIn>(
          onInvoke: (TimelineZoomIn intent) => () {
            timelinePaneProvider.requestTimelineZoomIn();
          }(),
        ),
        TimelineZoomOut: CallbackAction<TimelineZoomOut>(
          onInvoke: (TimelineZoomOut intent) => () {
            timelinePaneProvider.requestTimelineZoomOut();
          }(),
        ),
        TimingPointAddIntent: CallbackAction<TimingPointAddIntent>(
          onInvoke: (TimingPointAddIntent intent) => () {
            List<LyricSnippetID> selectingSnippetIDs = timelinePaneProvider.selectingSnippet;
            int charCursorPosition = textPaneProvider.cursorCharPosition;
            int seekPosition = musicPlayerProvider.seekPosition;
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              timingProvider.requestToAddLyricTiming(id, charCursorPosition, seekPosition);
            });
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            List<LyricSnippetID> selectingSnippetIDs = timelinePaneProvider.selectingSnippet;
            int charCursorPosition = textPaneProvider.cursorCharPosition;
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              timingProvider.requestToDeleteLyricTiming(id, charCursorPosition, Choice.former);
            });
          }(),
        ),
        SnippetDivideIntent: CallbackAction<SnippetDivideIntent>(
          onInvoke: (SnippetDivideIntent intent) => () {
            List<LyricSnippetID> selectedSnippetIDs = timelinePaneProvider.selectingSnippet;
            int charCursorPosition = textPaneProvider.cursorCharPosition;
            selectedSnippetIDs.forEach((LyricSnippetID id) {
              timingProvider.requestDivideSnippet(id, charCursorPosition);
              //masterSubject.add(RequestToExitTextSelectMode());
            });
          }(),
        ),
        SnippetConcatenateIntent: CallbackAction<SnippetConcatenateIntent>(
          onInvoke: (SnippetConcatenateIntent intent) => () {
            List<LyricSnippetID> selectedSnippetIDs = timelinePaneProvider.selectingSnippet;
            timingProvider.requestConcatenateSnippet(selectedSnippetIDs);
          }(),
        ),
        DisplayModeSwitchIntent: CallbackAction<DisplayModeSwitchIntent>(
          onInvoke: (DisplayModeSwitchIntent intent) => () {
            videoPaneProvider.requestSwitchDisplayMode();
          }(),
        ),
        TimelineCursorMoveLeft: CallbackAction<TimelineCursorMoveLeft>(
          onInvoke: (TimelineCursorMoveLeft intent) => () {
            timelinePaneProvider.requestTimelineCursorMoveRight();
          }(),
        ),
        TimelineCursorMoveDown: CallbackAction<TimelineCursorMoveDown>(
          onInvoke: (TimelineCursorMoveDown intent) => () {
            timelinePaneProvider.requestTimelineCursorMoveDown();
          }(),
        ),
        TimelineCursorMoveUp: CallbackAction<TimelineCursorMoveUp>(
          onInvoke: (TimelineCursorMoveUp intent) => () {
            timelinePaneProvider.requestTimelineCursorMoveUp();
          }(),
        ),
        TimelineCursorMoveRight: CallbackAction<TimelineCursorMoveRight>(
          onInvoke: (TimelineCursorMoveRight intent) => () {
            timelinePaneProvider.requestTimelineCursorMoveLeft();
          }(),
        ),
      };

  @override
  Widget build(BuildContext context) {
    bool enable = keyboardShortcutsProvider.enable;
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
        shortcuts: <LogicalKeySet, Intent>{},
        child: Actions(
          actions: <Type, Action<Intent>>{},
          child: child,
        ),
      );
    }
  }
}

class PlayPauseIntent extends Intent {}

class ForwardIntent extends Intent {}

class RewindIntent extends Intent {}

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

class TimelineZoomIn extends Intent {}

class TimelineZoomOut extends Intent {}

class TimingPointAddIntent extends Intent {}

class TimingPointDeleteIntent extends Intent {}

class SnippetDivideIntent extends Intent {}

class SnippetConcatenateIntent extends Intent {}

class DisplayModeSwitchIntent extends Intent {}

class TimelineCursorMoveLeft extends Intent {}

class TimelineCursorMoveDown extends Intent {}

class TimelineCursorMoveUp extends Intent {}

class TimelineCursorMoveRight extends Intent {}
