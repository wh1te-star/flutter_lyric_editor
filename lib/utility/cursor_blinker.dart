import 'dart:async';
import 'dart:ui';

class CursorBlinker {
  int blinkIntervalInMillisec;
  bool isCursorVisible = true;
  late Timer cursorTimer;
  late VoidCallback onTick;

  CursorBlinker({this.blinkIntervalInMillisec = 1000, required this.onTick}) {
    cursorTimer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      isCursorVisible = !isCursorVisible;
      onTick();
    });
  }

  void pauseCursorTimer() {
    cursorTimer.cancel();
  }

  void restartCursorTimer() {
    cursorTimer.cancel();
    isCursorVisible = true;
    cursorTimer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      isCursorVisible = !isCursorVisible;
      onTick();
    });
  }
}
