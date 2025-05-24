import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';

class InvalidInsertionPositionInfo implements InsertionPositionInfo {
  InvalidInsertionPositionInfo();

  InvalidInsertionPositionInfo copyWith() {
    return InvalidInsertionPositionInfo();
  }

  @override
  String toString() {
    return "InvalidInsertionPositionInfo";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! InvalidInsertionPositionInfo) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
