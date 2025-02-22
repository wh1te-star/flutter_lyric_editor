import 'dart:async';
import 'dart:ui';

class CursorBlinker {
  int blinkIntervalInMillisec;
  VoidCallback onTick;

  bool _visible = true;
  late Timer _timer;

  CursorBlinker._privateConstructor(this.blinkIntervalInMillisec, this.onTick);
  static final CursorBlinker _empty = CursorBlinker._privateConstructor(-1, () {});
  static CursorBlinker get empty => _empty;
  bool get isEmpty => identical(this, _empty);

  bool get visible => _visible;

  CursorBlinker({this.blinkIntervalInMillisec = 1000, required this.onTick}) {
    _timer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      _visible = !_visible;
      onTick();
    });
  }

  void pauseCursorTimer() {
    _timer.cancel();
  }

  void restartCursorTimer() {
    _timer.cancel();
    _visible = true;
    _timer = Timer.periodic(Duration(milliseconds: blinkIntervalInMillisec), (timer) {
      _visible = !_visible;
      onTick();
    });
  }

  CursorBlinker copyWith({int? blinkIntervalInMillisec, VoidCallback? onTick}) {
    return CursorBlinker(
      blinkIntervalInMillisec: blinkIntervalInMillisec ?? this.blinkIntervalInMillisec,
      onTick: onTick ?? this.onTick,
    );
  }

  @override
  String toString() {
    return "CursorBlinker interval: $blinkIntervalInMillisec, visible: $visible";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final CursorBlinker otherSentenceSegments = other as CursorBlinker;
    return blinkIntervalInMillisec == otherSentenceSegments.blinkIntervalInMillisec && onTick == otherSentenceSegments.onTick;
  }

  @override
  int get hashCode => blinkIntervalInMillisec.hashCode ^ onTick.hashCode;
}
