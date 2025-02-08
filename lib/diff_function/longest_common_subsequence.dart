import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/lcs_cell.dart';

class LongestCommonSequence {
  final String _firstStr;
  final String _secondStr;
  late List<List<LCSCell>> _lcsTable;

  LongestCommonSequence({
    required String firstStr,
    required String secondStr,
  })  : _secondStr = secondStr,
        _firstStr = firstStr {
    assert(_firstStr != "" || _secondStr != "");
    _lcsTable = constructLCSTable();
  }

  get firstStr => _firstStr;
  get secondStr => _secondStr;
  LCSCell cell(int row, int column) {
    return _lcsTable[row][column];
  }

  List<List<LCSCell>> constructLCSTable() {
    int rowCount = _firstStr.length;
    int columnCount = _secondStr.length;
    List<List<LCSCell>> table = initLCSTable(rowCount, columnCount);

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

  List<List<LCSCell>> initLCSTable(int rowCount, int columnCount) {
    return List.generate(
      rowCount + 1,
      (_) => List.generate(
        columnCount + 1,
        (_) => LCSCell(
          fromLeft: false,
          fromUpper: false,
          fromLeftUpper: false,
          lcsLength: 0,
        ),
      ),
    );
  }

  LCSCell handleMatch(List<List<LCSCell>> table, int firstIndex, int secondIndex) {
    return LCSCell(
      fromLeft: false,
      fromUpper: false,
      fromLeftUpper: true,
      lcsLength: table[firstIndex - 1][secondIndex - 1].lcsLength + 1,
    );
  }

  LCSCell handleUnmatch(List<List<LCSCell>> table, int firstIndex, int secondIndex) {
    int leftValue = table[firstIndex][secondIndex - 1].lcsLength;
    int upperValue = table[firstIndex - 1][secondIndex].lcsLength;

    if (leftValue > upperValue) {
      return LCSCell(
        fromLeft: true,
        fromUpper: false,
        fromLeftUpper: false,
        lcsLength: leftValue,
      );
    } else if (leftValue < upperValue) {
      return LCSCell(
        fromLeft: false,
        fromUpper: true,
        fromLeftUpper: false,
        lcsLength: upperValue,
      );
    } else {
      return LCSCell(
        fromLeft: true,
        fromUpper: true,
        fromLeftUpper: false,
        lcsLength: leftValue,
      );
    }
  }

  List<List<BacktrackCell>> constructBacktrackSteps() {
    List<List<BacktrackCell>> steps = [];
    return steps;
  }

  @override
  String toString() {
    return _lcsTable.map((row) => row.join("\t")).join("\n");
  }
}
