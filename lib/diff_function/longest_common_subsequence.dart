import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';

class LongestCommonSequence {
  final String _firstStr;
  final String _secondStr;
  late List<List<LCMCell>> _lcmTable;
  late List<List<BacktrackCell>> _backtrackSteps;

  LongestCommonSequence({
    required String firstStr,
    required String secondStr,
  })  : _secondStr = secondStr,
        _firstStr = firstStr {
    assert(_firstStr != "" || _secondStr != "");
    _lcmTable = constructLCMTable();
    _backtrackSteps = constructBacktrackSteps();
  }

  LCMCell cell(int row, int column) {
    return _lcmTable[row][column];
  }

  List<List<LCMCell>> constructLCMTable() {
    int rowCount = _firstStr.length;
    int columnCount = _secondStr.length;
    List<List<LCMCell>> table = initLCMTable(rowCount, columnCount);

    for (int firstIndex = 1; firstIndex <= rowCount; firstIndex++) {
      for (int secondIndex = 1; secondIndex <= columnCount; secondIndex++) {
        if (_firstStr[firstIndex - 1] == _secondStr[secondIndex - 1]) {
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

  List<List<BacktrackCell>> constructBacktrackSteps() {
    List<List<BacktrackCell>> steps = [];
    return steps;
  }
}
