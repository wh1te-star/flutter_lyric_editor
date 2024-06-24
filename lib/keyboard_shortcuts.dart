import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/lyric_snippet.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class KeyboardShortcuts extends StatelessWidget {
  final PublishSubject<dynamic> masterSubject;
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  List<LyricSnippet> currentSnippets = [];
  List<String> selectingVocalist = [];
  int seekPosition = 0;
  int charCursorPosition = 0;

  bool textSelectMode = false;
  int selectedPosition = 0;
  LyricSnippetID selectedSnippetID = LyricSnippetID("", 0);

  KeyboardShortcuts({
    required this.masterSubject,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  }) {
    masterSubject.stream.listen((signal) {
      if (signal is NotifyCurrentSnippets) {
        currentSnippets = signal.currentSnippets;
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
      if (signal is NotifyCharCursorPosition) {
        charCursorPosition = signal.cursorPosition;
      }
      if (signal is NotifyLineCursorPosition) {
        selectedSnippetID = signal.cursorSnippetID;
      }
    });
  }

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space):
            ActivateSpaceKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyD): ActivateDKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): ActivateFKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): ActivateCKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): ActivateVKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            ActivateLeftArrowKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            ActivateRightArrowKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp):
            ActivateUpArrowKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            ActivateDownArrowKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): ActivateHKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): ActivateJKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyK): ActivateKKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateLKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK):
            ActivateCtrlKKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyJ):
            ActivateCtrlJKeyShortcutIntent(),
        //LogicalKeySet(LogicalKeyboardKey.keyB): ActivateBKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter):
            ActivateEnterKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyN): ActivateNKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM): ActivateMKeyShortcutIntent(),
      };

  Map<Type, Action<Intent>> get actions => {
        ActivateSpaceKeyShortcutIntent:
            CallbackAction<ActivateSpaceKeyShortcutIntent>(
          onInvoke: (ActivateSpaceKeyShortcutIntent intent) => () {
            masterSubject.add(RequestPlayPause());
          }(),
        ),
        ActivateDKeyShortcutIntent: CallbackAction<ActivateDKeyShortcutIntent>(
          onInvoke: (ActivateDKeyShortcutIntent intent) => () {
            masterSubject.add(RequestRewind(1000));
          }(),
        ),
        ActivateFKeyShortcutIntent: CallbackAction<ActivateFKeyShortcutIntent>(
          onInvoke: (ActivateFKeyShortcutIntent intent) => () {
            masterSubject.add(RequestForward(1000));
          }(),
        ),
        ActivateCKeyShortcutIntent: CallbackAction<ActivateCKeyShortcutIntent>(
          onInvoke: (ActivateCKeyShortcutIntent intent) => () {
            masterSubject.add(RequestSnippetMove(SnippetEdge.start, false));
          }(),
        ),
        ActivateVKeyShortcutIntent: CallbackAction<ActivateVKeyShortcutIntent>(
          onInvoke: (ActivateVKeyShortcutIntent intent) => () {
            masterSubject.add(RequestSnippetMove(SnippetEdge.end, false));
          }(),
        ),
        ActivateUpArrowKeyShortcutIntent:
            CallbackAction<ActivateUpArrowKeyShortcutIntent>(
          onInvoke: (ActivateUpArrowKeyShortcutIntent intent) => () {
            masterSubject.add(RequestVolumeUp(0.1));
          }(),
        ),
        ActivateDownArrowKeyShortcutIntent:
            CallbackAction<ActivateDownArrowKeyShortcutIntent>(
          onInvoke: (ActivateDownArrowKeyShortcutIntent intent) => () {
            masterSubject.add(RequestVolumeDown(0.1));
          }(),
        ),
        ActivateRightArrowKeyShortcutIntent:
            CallbackAction<ActivateRightArrowKeyShortcutIntent>(
          onInvoke: (ActivateRightArrowKeyShortcutIntent intent) => () {
            masterSubject.add(RequestSpeedUp(0.1));
          }(),
        ),
        ActivateLeftArrowKeyShortcutIntent:
            CallbackAction<ActivateLeftArrowKeyShortcutIntent>(
          onInvoke: (ActivateLeftArrowKeyShortcutIntent intent) => () {
            masterSubject.add(RequestSpeedDown(0.1));
          }(),
        ),
        ActivateHKeyShortcutIntent: CallbackAction<ActivateHKeyShortcutIntent>(
          onInvoke: (ActivateHKeyShortcutIntent intent) => () {
            masterSubject.add(RequestMoveLeftCharCursor());
          }(),
        ),
        ActivateJKeyShortcutIntent: CallbackAction<ActivateJKeyShortcutIntent>(
          onInvoke: (ActivateJKeyShortcutIntent intent) => () {
            masterSubject.add(RequestMoveDownCharCursor());
          }(),
        ),
        ActivateKKeyShortcutIntent: CallbackAction<ActivateKKeyShortcutIntent>(
          onInvoke: (ActivateKKeyShortcutIntent intent) => () {
            masterSubject.add(RequestMoveUpCharCursor());
          }(),
        ),
        ActivateLKeyShortcutIntent: CallbackAction<ActivateLKeyShortcutIntent>(
          onInvoke: (ActivateLKeyShortcutIntent intent) => () {
            masterSubject.add(RequestMoveRightCharCursor());
          }(),
        ),
        ActivateCtrlKKeyShortcutIntent:
            CallbackAction<ActivateCtrlKKeyShortcutIntent>(
          onInvoke: (ActivateCtrlKKeyShortcutIntent intent) => () {
            masterSubject.add(RequestTimelineZoomIn());
          }(),
        ),
        ActivateCtrlJKeyShortcutIntent:
            CallbackAction<ActivateCtrlJKeyShortcutIntent>(
          onInvoke: (ActivateCtrlJKeyShortcutIntent intent) => () {
            masterSubject.add(RequestTimelineZoomOut());
          }(),
        ),
        ActivateNKeyShortcutIntent: CallbackAction<ActivateNKeyShortcutIntent>(
          onInvoke: (ActivateNKeyShortcutIntent intent) => () {
            currentSnippets.forEach((LyricSnippet snippet) {
              if (selectingVocalist.contains(snippet.vocalist)) {
                masterSubject.add(RequestToAddLyricTiming(
                    snippet.id, charCursorPosition, seekPosition));
              }
            });
          }(),
        ),
        ActivateMKeyShortcutIntent: CallbackAction<ActivateMKeyShortcutIntent>(
          onInvoke: (ActivateMKeyShortcutIntent intent) => () {
            currentSnippets.forEach((LyricSnippet snippet) {
              if (selectingVocalist.contains(snippet.vocalist)) {
                masterSubject.add(
                    RequestToDeleteLyricTiming(snippet.id, charCursorPosition));
              }
            });
          }(),
        ),
        ActivateEnterKeyShortcutIntent:
            CallbackAction<ActivateEnterKeyShortcutIntent>(
          onInvoke: (ActivateEnterKeyShortcutIntent intent) => () {
            masterSubject.add(
                RequestToMakeSnippet(selectedSnippetID, charCursorPosition));
            textSelectMode = false;
            masterSubject.add(RequestToExitTextSelectMode());
          }(),
        ),
      };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: child,
      ),
    );
  }
}

class ActivateSpaceKeyShortcutIntent extends Intent {}

class ActivateFKeyShortcutIntent extends Intent {}

class ActivateDKeyShortcutIntent extends Intent {}

class ActivateCKeyShortcutIntent extends Intent {}

class ActivateVKeyShortcutIntent extends Intent {}

class ActivateUpArrowKeyShortcutIntent extends Intent {}

class ActivateDownArrowKeyShortcutIntent extends Intent {}

class ActivateRightArrowKeyShortcutIntent extends Intent {}

class ActivateLeftArrowKeyShortcutIntent extends Intent {}

class ActivateJKeyShortcutIntent extends Intent {}

class ActivateKKeyShortcutIntent extends Intent {}

class ActivateHKeyShortcutIntent extends Intent {}

class ActivateLKeyShortcutIntent extends Intent {}

class ActivateCtrlKKeyShortcutIntent extends Intent {}

class ActivateCtrlJKeyShortcutIntent extends Intent {}

class ActivateEnterKeyShortcutIntent extends Intent {}

class ActivateNKeyShortcutIntent extends Intent {}

class ActivateMKeyShortcutIntent extends Intent {}
