import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class KeyboardShortcuts extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  KeyboardShortcuts({
    required this.masterSubject,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  _KeyboardShortcutsState createState() => _KeyboardShortcutsState(masterSubject: this.masterSubject, child: this.child, videoPaneFocusNode: this.videoPaneFocusNode, textPaneFocusNode: this.textPaneFocusNode, timelinePaneFocusNode: this.timelinePaneFocusNode);
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  final PublishSubject<dynamic> masterSubject;
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  bool enable = true;

  List<LyricSnippetID> selectingSnippetIDs = [];
  List<String> selectingVocalist = [];
  int seekPosition = 0;
  int charCursorPosition = 0;
  Option cursorPositionOption = Option.former;

  List<int> sections = [];

  bool textSelectMode = false;
  int selectedPosition = 0;
  LyricSnippetID selectedSnippetID = LyricSnippetID(Vocalist("", 0), 0);

  _KeyboardShortcutsState({
    required this.masterSubject,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  void initState() {
    super.initState();

    widget.masterSubject.stream.listen((signal) {
      if (signal is RequestKeyboardShortcutEnable) {
        enable = signal.enable;
        debugPrint("enable: ${enable}");
        setState(() {});
        NotifyKeyboardShortcutEnable(enable);
      }
      if (signal is NotifySelectingSnippets) {
        selectingSnippetIDs = signal.snippetIDs;
      }
      if (signal is NotifySelectingVocalist) {
        selectingVocalist.add(signal.vocalistName);
      }
      if (signal is NotifyDeselectingVocalist) {
        selectingVocalist.remove(signal.vocalistName);
      }
      if (signal is NotifySeekPosition) {
        seekPosition = signal.seekPosition;
      }
      if (signal is NotifySectionAdded || signal is NotifySectionDeleted) {
        sections = signal.sections;
      }
      if (signal is NotifyCharCursorPosition) {
        charCursorPosition = signal.cursorPosition;
        cursorPositionOption = signal.option;
      }
      if (signal is NotifyLineCursorPosition) {
        selectedSnippetID = signal.cursorSnippetID;
      }
    });
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
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): TimelineZoomIn(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyJ): TimelineZoomOut(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA): AddSectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): DeleteSectionIntent(),
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
            masterSubject.add(RequestPlayPause());
          }(),
        ),
        RewindIntent: CallbackAction<RewindIntent>(
          onInvoke: (RewindIntent intent) => () {
            masterSubject.add(RequestRewind(1000));
          }(),
        ),
        ForwardIntent: CallbackAction<ForwardIntent>(
          onInvoke: (ForwardIntent intent) => () {
            masterSubject.add(RequestForward(1000));
          }(),
        ),
        SnippetStartMoveIntent: CallbackAction<SnippetStartMoveIntent>(
          onInvoke: (SnippetStartMoveIntent intent) => () {
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              masterSubject.add(RequestSnippetMove(id, SnippetEdge.start, true));
            });
          }(),
        ),
        SnippetEndMoveIntent: CallbackAction<SnippetEndMoveIntent>(
          onInvoke: (SnippetEndMoveIntent intent) => () {
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              masterSubject.add(RequestSnippetMove(id, SnippetEdge.end, false));
            });
          }(),
        ),
        VolumeUpIntent: CallbackAction<VolumeUpIntent>(
          onInvoke: (VolumeUpIntent intent) => () {
            masterSubject.add(RequestVolumeUp(0.1));
          }(),
        ),
        VolumeDownIntent: CallbackAction<VolumeDownIntent>(
          onInvoke: (VolumeDownIntent intent) => () {
            masterSubject.add(RequestVolumeDown(0.1));
          }(),
        ),
        SpeedUpIntent: CallbackAction<SpeedUpIntent>(
          onInvoke: (SpeedUpIntent intent) => () {
            masterSubject.add(RequestSpeedUp(0.1));
          }(),
        ),
        SpeedDownIntent: CallbackAction<SpeedDownIntent>(
          onInvoke: (SpeedDownIntent intent) => () {
            masterSubject.add(RequestSpeedDown(0.1));
          }(),
        ),
        TextPaneCursorMoveLeftIntent: CallbackAction<TextPaneCursorMoveLeftIntent>(
          onInvoke: (TextPaneCursorMoveLeftIntent intent) => () {
            masterSubject.add(RequestMoveLeftCharCursor());
          }(),
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (UndoIntent intent) => () {
            masterSubject.add(RequestUndo());
          }(),
        ),
        TextPaneCursorMoveDownIntent: CallbackAction<TextPaneCursorMoveDownIntent>(
          onInvoke: (TextPaneCursorMoveDownIntent intent) => () {
            masterSubject.add(RequestMoveDownCharCursor());
          }(),
        ),
        TextPaneCursorMoveUpIntent: CallbackAction<TextPaneCursorMoveUpIntent>(
          onInvoke: (TextPaneCursorMoveUpIntent intent) => () {
            masterSubject.add(RequestMoveUpCharCursor());
          }(),
        ),
        TextPaneCursorMoveRightIntent: CallbackAction<TextPaneCursorMoveRightIntent>(
          onInvoke: (TextPaneCursorMoveRightIntent intent) => () {
            masterSubject.add(RequestMoveRightCharCursor());
          }(),
        ),
        TimelineZoomIn: CallbackAction<TimelineZoomIn>(
          onInvoke: (TimelineZoomIn intent) => () {
            masterSubject.add(RequestTimelineZoomIn());
          }(),
        ),
        TimelineZoomOut: CallbackAction<TimelineZoomOut>(
          onInvoke: (TimelineZoomOut intent) => () {
            masterSubject.add(RequestTimelineZoomOut());
          }(),
        ),
        AddSectionIntent: CallbackAction<AddSectionIntent>(
          onInvoke: (AddSectionIntent intent) => () {
            masterSubject.add(RequestAddSection(seekPosition));
          }(),
        ),
        DeleteSectionIntent: CallbackAction<DeleteSectionIntent>(
          onInvoke: (DeleteSectionIntent intent) => () {
            masterSubject.add(RequestDeleteSection(seekPosition));
          }(),
        ),
        TimingPointAddIntent: CallbackAction<TimingPointAddIntent>(
          onInvoke: (TimingPointAddIntent intent) => () {
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              masterSubject.add(RequestToAddTimingPoint(id, charCursorPosition, seekPosition));
            });
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            selectingSnippetIDs.forEach((LyricSnippetID id) {
              masterSubject.add(RequestToDeleteTimingPoint(
                id,
                charCursorPosition,
              ));
            });
          }(),
        ),
        SnippetDivideIntent: CallbackAction<SnippetDivideIntent>(
          onInvoke: (SnippetDivideIntent intent) => () {
            masterSubject.add(RequestDivideSnippet(selectedSnippetID, charCursorPosition));
            //masterSubject.add(RequestToExitTextSelectMode());
          }(),
        ),
        SnippetConcatenateIntent: CallbackAction<SnippetConcatenateIntent>(
          onInvoke: (SnippetConcatenateIntent intent) => () {
            masterSubject.add(RequestConcatenateSnippet(selectingSnippetIDs));
          }(),
        ),
        DisplayModeSwitchIntent: CallbackAction<DisplayModeSwitchIntent>(
          onInvoke: (DisplayModeSwitchIntent intent) => () {
            masterSubject.add(RequestSwitchDisplayMode());
          }(),
        ),
        TimelineCursorMoveLeft: CallbackAction<TimelineCursorMoveLeft>(
          onInvoke: (TimelineCursorMoveLeft intent) => () {
            masterSubject.add(RequestTimelineCursorMoveRight());
          }(),
        ),
        TimelineCursorMoveDown: CallbackAction<TimelineCursorMoveDown>(
          onInvoke: (TimelineCursorMoveDown intent) => () {
            masterSubject.add(RequestTimelineCursorMoveDown());
          }(),
        ),
        TimelineCursorMoveUp: CallbackAction<TimelineCursorMoveUp>(
          onInvoke: (TimelineCursorMoveUp intent) => () {
            masterSubject.add(RequestTimelineCursorMoveUp());
          }(),
        ),
        TimelineCursorMoveRight: CallbackAction<TimelineCursorMoveRight>(
          onInvoke: (TimelineCursorMoveRight intent) => () {
            masterSubject.add(RequestTimelineCursorMoveLeft());
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
