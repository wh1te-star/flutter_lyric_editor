import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class KeyboardShortcuts extends StatelessWidget {
  final PublishSubject<dynamic> masterSubject;
  final Widget child;

  KeyboardShortcuts({required this.masterSubject, required this.child});

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space): ActivatePlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyD): ActivateRewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): ActivateForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ActivateSpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ActivateSpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): ActivateVolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): ActivateVolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): ActivateMoveLeftCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): ActivateMoveDownCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyK): ActivateMoveUpCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateMoveRightCursor(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK):
            ActivateTimelineZoomIn(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyJ):
            ActivateTimelineZoomOut(),
      };

  Map<Type, Action<Intent>> get actions => {
        ActivatePlayPauseIntent: CallbackAction<ActivatePlayPauseIntent>(
          onInvoke: (ActivatePlayPauseIntent intent) => () {
            masterSubject.add(RequestPlayPause());
          }(),
        ),
        ActivateRewindIntent: CallbackAction<ActivateRewindIntent>(
          onInvoke: (ActivateRewindIntent intent) => () {
            masterSubject.add(RequestRewind(1000));
          }(),
        ),
        ActivateForwardIntent: CallbackAction<ActivateForwardIntent>(
          onInvoke: (ActivateForwardIntent intent) => () {
            masterSubject.add(RequestForward(1000));
          }(),
        ),
        ActivateVolumeUpIntent: CallbackAction<ActivateVolumeUpIntent>(
          onInvoke: (ActivateVolumeUpIntent intent) => () {
            masterSubject.add(RequestVolumeUp(0.1));
          }(),
        ),
        ActivateVolumeDownIntent: CallbackAction<ActivateVolumeDownIntent>(
          onInvoke: (ActivateVolumeDownIntent intent) => () {
            masterSubject.add(RequestVolumeDown(0.1));
          }(),
        ),
        ActivateSpeedUpIntent: CallbackAction<ActivateSpeedUpIntent>(
          onInvoke: (ActivateSpeedUpIntent intent) => () {
            masterSubject.add(RequestSpeedUp(0.1));
          }(),
        ),
        ActivateSpeedDownIntent: CallbackAction<ActivateSpeedDownIntent>(
          onInvoke: (ActivateSpeedDownIntent intent) => () {
            masterSubject.add(RequestSpeedDown(0.1));
          }(),
        ),
        ActivateMoveLeftCursor: CallbackAction<ActivateMoveLeftCursor>(
          onInvoke: (ActivateMoveLeftCursor intent) => () {
            masterSubject.add(RequestMoveLeftCharCursor());
          }(),
        ),
        ActivateMoveDownCursor: CallbackAction<ActivateMoveDownCursor>(
          onInvoke: (ActivateMoveDownCursor intent) => () {
            masterSubject.add(RequestMoveDownCharCursor());
          }(),
        ),
        ActivateMoveUpCursor: CallbackAction<ActivateMoveUpCursor>(
          onInvoke: (ActivateMoveUpCursor intent) => () {
            masterSubject.add(RequestMoveUpCharCursor());
          }(),
        ),
        ActivateMoveRightCursor: CallbackAction<ActivateMoveRightCursor>(
          onInvoke: (ActivateMoveRightCursor intent) => () {
            masterSubject.add(RequestMoveRightCharCursor());
          }(),
        ),
        ActivateTimelineZoomIn: CallbackAction<ActivateTimelineZoomIn>(
          onInvoke: (ActivateTimelineZoomIn intent) => () {
            masterSubject.add(RequestTimelineZoomIn());
          }(),
        ),
        ActivateTimelineZoomOut: CallbackAction<ActivateTimelineZoomOut>(
          onInvoke: (ActivateTimelineZoomOut intent) => () {
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
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class ActivatePlayPauseIntent extends Intent {}

class ActivateForwardIntent extends Intent {}

class ActivateRewindIntent extends Intent {}

class ActivateVolumeUpIntent extends Intent {}

class ActivateVolumeDownIntent extends Intent {}

class ActivateSpeedUpIntent extends Intent {}

class ActivateSpeedDownIntent extends Intent {}

class ActivateMoveDownCursor extends Intent {}

class ActivateMoveUpCursor extends Intent {}

class ActivateMoveLeftCursor extends Intent {}

class ActivateMoveRightCursor extends Intent {}

class ActivateTimelineZoomIn extends Intent {}

class ActivateTimelineZoomOut extends Intent {}
