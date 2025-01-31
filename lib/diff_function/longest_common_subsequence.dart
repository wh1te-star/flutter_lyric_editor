import 'package:lyric_editor/diff_function/lcm_cell.dart';

class LongestCommonSequence {
  final String firstStr;
  final String secondStr;
  late List<List<LCMCell>> lcmTable;

  LongestCommonSequence({
    required this.firstStr,
    required this.secondStr,
  }) {
    assert(firstStr != "" || secondStr != "");

    lcmTable = constructLCMTable(firstStr, secondStr);
  }

  List<List<LCMCell>> constructLCMTable(String firstStr, String secondStr) {
    int rowCount = firstStr.length;
    int columnCount = secondStr.length;
    List<List<LCMCell>> lcmTable = List.generate(
      rowCount + 1,
      (_) => List.generate(
        columnCount + 1,
        (_) => LCMCell(
          fromLeft: false,
          fromUpper: false,
          fromLeftUpper: false,
          lcmLength: 0,
        ),
      ),
    );

    for (int firstIndex = 1; firstIndex <= rowCount; firstIndex++) {
      for (int secondIndex = 1; secondIndex <= columnCount; secondIndex++) {
        if (firstStr[firstIndex - 1] == secondStr[secondIndex - 1]) {
          lcmTable[firstIndex][secondIndex] = LCMCell(
            fromLeft: false,
            fromUpper: false,
            fromLeftUpper: true,
            lcmLength: lcmTable[firstIndex - 1][secondIndex - 1].lcmLength + 1,
          );
        } else {
          int leftValue = lcmTable[firstIndex][secondIndex - 1].lcmLength;
          int upperValue = lcmTable[firstIndex - 1][secondIndex].lcmLength;
          if (leftValue > upperValue) {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: true,
              fromUpper: false,
              fromLeftUpper: false,
              lcmLength: leftValue,
            );
          } else if (leftValue < upperValue) {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: false,
              fromUpper: true,
              fromLeftUpper: false,
              lcmLength: upperValue,
            );
          } else {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: true,
              fromUpper: true,
              fromLeftUpper: false,
              lcmLength: leftValue,
            );
          }
        }
      }
    }

    return lcmTable;
  }
}
