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

  KeyboardShortcuts({
    required this.masterSubject,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

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
        LogicalKeySet(LogicalKeyboardKey.keyH): ActivateHKeyShortcutCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): ActivateJKeyShortcutCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyK): ActivateKKeyShortcutCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateLKeyShortcutCursor(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK):
            ActivateCtrlKKeyShortcutCursor(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyJ):
            ActivateCtrlJKeyShortcutCursor(),
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
        ActivateHKeyShortcutCursor: CallbackAction<ActivateHKeyShortcutCursor>(
          onInvoke: (ActivateHKeyShortcutCursor intent) => () {
            if (textPaneFocusNode.hasFocus) {
              masterSubject.add(RequestMoveLeftCharCursor());
            }
            if (timelinePaneFocusNode.hasFocus) {
              masterSubject.add(RequestRewind(1000));
            }
          }(),
        ),
        ActivateJKeyShortcutCursor: CallbackAction<ActivateJKeyShortcutCursor>(
          onInvoke: (ActivateJKeyShortcutCursor intent) => () {
            masterSubject.add(RequestMoveDownCharCursor());
          }(),
        ),
        ActivateKKeyShortcutCursor: CallbackAction<ActivateKKeyShortcutCursor>(
          onInvoke: (ActivateKKeyShortcutCursor intent) => () {
            masterSubject.add(RequestMoveUpCharCursor());
          }(),
        ),
        ActivateLKeyShortcutCursor: CallbackAction<ActivateLKeyShortcutCursor>(
          onInvoke: (ActivateLKeyShortcutCursor intent) => () {
            if (textPaneFocusNode.hasFocus) {
              masterSubject.add(RequestMoveRightCharCursor());
            }
            if (timelinePaneFocusNode.hasFocus) {
              masterSubject.add(RequestForward(1000));
            }
          }(),
        ),
        ActivateCtrlKKeyShortcutCursor:
            CallbackAction<ActivateCtrlKKeyShortcutCursor>(
          onInvoke: (ActivateCtrlKKeyShortcutCursor intent) => () {
            masterSubject.add(RequestTimelineZoomIn());
          }(),
        ),
        ActivateCtrlJKeyShortcutCursor:
            CallbackAction<ActivateCtrlJKeyShortcutCursor>(
          onInvoke: (ActivateCtrlJKeyShortcutCursor intent) => () {
            masterSubject.add(RequestTimelineZoomOut());
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

class ActivateJKeyShortcutCursor extends Intent {}

class ActivateKKeyShortcutCursor extends Intent {}

class ActivateHKeyShortcutCursor extends Intent {}

class ActivateLKeyShortcutCursor extends Intent {}

class ActivateCtrlKKeyShortcutCursor extends Intent {}

class ActivateCtrlJKeyShortcutCursor extends Intent {}
