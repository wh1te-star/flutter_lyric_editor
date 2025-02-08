import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

class BacktrackTable {
  final LongestCommonSequence _lcm;
  List<List<BacktrackCell>> _backtrackTable = [];
  List<BacktrackRoute> _routes = [];

  BacktrackTable({required LongestCommonSequence lcm}) : _lcm = lcm {
    foundRoute();
  }

  void foundRoute() {
    initBacktrackTable();

    fillBacktrackTable();

    _routes = normalizeFoundRoutes();
  }

  void initBacktrackTable() {
    int rowCount = _lcm.firstStr.length;
    int columnCount = _lcm.secondStr.length;
    _backtrackTable = List.generate(
      rowCount + 1,
      (rowIndex) => List.generate(
        columnCount + 1,
        (columnIndex) {
          if (rowIndex == rowCount && columnIndex == columnCount) {
            return BacktrackCell([BacktrackRoute.dummyRoute()]);
          } else {
            return BacktrackCell([]);
          }
        },
      ),
    );
  }

  void fillBacktrackTable() {
    int rowCount = _lcm.firstStr.length;
    int columnCount = _lcm.secondStr.length;
    for (int firstIndex = rowCount; firstIndex >= 0; firstIndex--) {
      for (int secondIndex = columnCount; secondIndex >= 0; secondIndex--) {
        bool isLowerIn = firstIndex + 1 <= rowCount;
        bool isRightIn = secondIndex + 1 <= columnCount;
        LCMCell? rightLCMCell;
        LCMCell? lowerLCMCell;
        LCMCell? rightLowerLCMCell;
        if (isRightIn) {
          rightLCMCell = _lcm.cell(firstIndex, secondIndex + 1);
        }
        if (isLowerIn) {
          lowerLCMCell = _lcm.cell(firstIndex + 1, secondIndex);
        }
        if (isRightIn && isLowerIn) {
          rightLowerLCMCell = _lcm.cell(firstIndex + 1, secondIndex + 1);
        }

        if (rightLCMCell != null && lowerLCMCell != null && rightLowerLCMCell != null && rightLowerLCMCell.fromLeftUpper) {
          BacktrackCell newBacktrackCell = _backtrackTable[firstIndex + 1][secondIndex + 1].addNewPoint(firstIndex, secondIndex);
          _backtrackTable[firstIndex][secondIndex] = newBacktrackCell;
        }
        if (rightLCMCell != null && rightLCMCell.fromLeft) {
          BacktrackCell newBacktrackCell = _backtrackTable[firstIndex][secondIndex].inheritRoutes(_backtrackTable[firstIndex][secondIndex + 1]);
          _backtrackTable[firstIndex][secondIndex] = newBacktrackCell;
        }
        if (lowerLCMCell != null && lowerLCMCell.fromUpper) {
          BacktrackCell newBacktrackCell = _backtrackTable[firstIndex][secondIndex].inheritRoutes(_backtrackTable[firstIndex + 1][secondIndex]);
          _backtrackTable[firstIndex][secondIndex] = newBacktrackCell;
        }
      }
    }
  }

  List<BacktrackRoute> normalizeFoundRoutes() {
    int rowCount = _lcm.firstStr.length;
    int columnCount = _lcm.secondStr.length;
    List<BacktrackRoute> routes = [];
    routes += _backtrackTable[0][0].normalizedRoutes();
    for (int row = 1; row <= rowCount; row++) {
      routes += _backtrackTable[row][0].normalizedRoutes();
    }
    for (int column = 1; column <= columnCount; column++) {
      routes += _backtrackTable[0][column].normalizedRoutes();
    }
    return routes;
  }

  List<BacktrackRoute> getCommonIndex() {
    return _routes;
  }

  @override
  String toString() {
    int rowCount = _lcm.firstStr.length;
    int columnCount = _lcm.secondStr.length;
    String output = "";
    for (int row = 0; row <= rowCount; row++) {
      for (int column = 0; column <= columnCount; column++) {
        BacktrackCell backtrackCell = _backtrackTable[row][column];
        LCMCell lcmCell = _lcm.cell(row, column);
        output += "${lcmCell}${backtrackCell.routes.length}, ";
      }
      output += "\n";
    }
    return output;
  }
}
