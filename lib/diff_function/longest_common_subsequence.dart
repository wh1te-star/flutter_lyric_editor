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
    List<List<LCMCell>> table = initLCMTable(rowCount, columnCount);

    for (int firstIndex = 1; firstIndex <= rowCount; firstIndex++) {
      for (int secondIndex = 1; secondIndex <= columnCount; secondIndex++) {
        if (firstStr[firstIndex - 1] == secondStr[secondIndex - 1]) {
          table[firstIndex][secondIndex] = handleMatch(table, firstIndex, secondIndex);
        } else {
          table[firstIndex][secondIndex] = handleUnmatch(table, firstIndex, secondIndex);
        }
      }
    }
    return table;
  }

  List<List<LCMCell>> initLCMTable(int rowCount, int columnCount) {
    return List.generate(
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
  }

  LCMCell handleMatch(List<List<LCMCell>> table, int firstIndex, int secondIndex) {
    return LCMCell(
      fromLeft: false,
      fromUpper: false,
      fromLeftUpper: true,
      lcmLength: table[firstIndex - 1][secondIndex - 1].lcmLength + 1,
    );
  }

  LCMCell handleUnmatch(List<List<LCMCell>> table, int firstIndex, int secondIndex) {
    int leftValue = table[firstIndex][secondIndex - 1].lcmLength;
    int upperValue = table[firstIndex - 1][secondIndex].lcmLength;

    if (leftValue > upperValue) {
      return LCMCell(
        fromLeft: true,
        fromUpper: false,
        fromLeftUpper: false,
        lcmLength: leftValue,
      );
    } else if (leftValue < upperValue) {
      return LCMCell(
        fromLeft: false,
        fromUpper: true,
        fromLeftUpper: false,
        lcmLength: upperValue,
      );
    }
    return LCMCell(
      fromLeft: true,
      fromUpper: true,
      fromLeftUpper: false,
      lcmLength: leftValue,
    );
  }
}
