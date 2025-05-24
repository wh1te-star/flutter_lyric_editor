import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';

class InvalidCaretPositionInfo implements CaretPositionInfo {
  InvalidCaretPositionInfo();

  InvalidCaretPositionInfo copyWith() {
    return InvalidCaretPositionInfo();
  }

  @override
  String toString() {
    return "InvalidCaretPositionInfo";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! InvalidCaretPositionInfo) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
