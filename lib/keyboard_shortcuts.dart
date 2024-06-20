import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class KeyboardShortcuts extends StatelessWidget {
  final PublishSubject<dynamic> masterSubject;
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  int snippetID = 0;
  int seekPosition = 0;
  int charCursorPosition = 0;

  KeyboardShortcuts({
    required this.masterSubject,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  }) {
    masterSubject.stream.listen((signal) {
      if (signal is NotifySelectingSnippet) {
        snippetID = signal.snippetID;
      }
      if (signal is NotifySeekPosition) {
        seekPosition = signal.seekPosition;
      }
      if (signal is NotifyCharCursorPosition) {
        charCursorPosition = signal.cursorPosition;
      }
    });
  }

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space):
            ActivateSpaceKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyD): ActivateDKeyShortcutIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): ActivateFKeyShortcutIntent(),
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
            if (textPaneFocusNode.hasFocus) {
              masterSubject.add(RequestMoveLeftCharCursor());
            }
            if (timelinePaneFocusNode.hasFocus) {
              masterSubject.add(RequestRewind(1000));
            }
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
            if (textPaneFocusNode.hasFocus) {
              masterSubject.add(RequestMoveRightCharCursor());
            }
            if (timelinePaneFocusNode.hasFocus) {
              masterSubject.add(RequestForward(1000));
            }
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
            masterSubject.add(RequestToAddLyricTiming(
                snippetID, charCursorPosition, seekPosition));
          }(),
        ),
        ActivateMKeyShortcutIntent: CallbackAction<ActivateMKeyShortcutIntent>(
          onInvoke: (ActivateMKeyShortcutIntent intent) => () {
            masterSubject
                .add(RequestToDeleteLyricTiming(snippetID, charCursorPosition));
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

class ActivateNKeyShortcutIntent extends Intent {}

class ActivateMKeyShortcutIntent extends Intent {}
