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
    int m = firstStr.length;
    int n = secondStr.length;
    List<List<LCMCell>> lcmTable = List.generate(
      m + 1,
      (_) => List.generate(
        n + 1,
        (_) => LCMCell(
          fromLeft: false,
          fromUpper: false,
          fromLeftUpper: false,
          lcmLength: 0,
        ),
      ),
    );

    for (int firstIndex = 1; firstIndex <= m; firstIndex++) {
      for (int secondIndex = 1; secondIndex <= n; secondIndex++) {
        if (firstStr[firstIndex - 1] == secondStr[secondIndex - 1]) {
          lcmTable[firstIndex][secondIndex] = LCMCell(
            fromLeft: false,
            fromUpper: false,
            fromLeftUpper: true,
            lcmLength: lcmTable[firstIndex - 1][secondIndex - 1].lcmLength + 1,
          );
        } else {
          if (lcmTable[firstIndex - 1][secondIndex].lcmLength > lcmTable[firstIndex][secondIndex - 1].lcmLength) {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: true,
              fromUpper: false,
              fromLeftUpper: false,
              lcmLength: lcmTable[firstIndex - 1][secondIndex].lcmLength,
            );
          } else if (lcmTable[firstIndex - 1][secondIndex].lcmLength < lcmTable[firstIndex][secondIndex - 1].lcmLength) {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: false,
              fromUpper: true,
              fromLeftUpper: false,
              lcmLength: lcmTable[firstIndex][secondIndex - 1].lcmLength,
            );
          } else {
            lcmTable[firstIndex][secondIndex] = LCMCell(
              fromLeft: true,
              fromUpper: true,
              fromLeftUpper: false,
              lcmLength: lcmTable[firstIndex - 1][secondIndex].lcmLength,
            );
          }
        }
      }
    }

    return lcmTable;
  }
}
