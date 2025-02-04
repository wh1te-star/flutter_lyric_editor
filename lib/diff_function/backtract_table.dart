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
    establishRoute();
  }

  void establishRoute() {
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

    for (int firstIndex = rowCount; firstIndex >= 0; firstIndex--) {
      for (int secondIndex = columnCount; secondIndex >= 0; secondIndex--) {
        LCMCell lcmCell = _lcm.cell(firstIndex, secondIndex);
        BacktrackCell backtrackCell = _backtrackTable[firstIndex][secondIndex];

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

        if (rightLCMCell != null && rightLCMCell.fromLeft) {
          BacktrackCell previousBacktrackCell = _backtrackTable[firstIndex][secondIndex + 1];
          backtrackCell = previousBacktrackCell.inheritRoutes(backtrackCell);
        }
        if (lowerLCMCell != null && lowerLCMCell.fromUpper) {
          BacktrackCell previousBacktrackCell = _backtrackTable[firstIndex + 1][secondIndex];
          backtrackCell = previousBacktrackCell.inheritRoutes(backtrackCell);
        }
        if (rightLCMCell != null && lowerLCMCell != null && rightLowerLCMCell != null && rightLowerLCMCell.fromLeftUpper) {
          BacktrackCell previousBacktrackCell = _backtrackTable[firstIndex + 1][secondIndex + 1];
          backtrackCell = previousBacktrackCell.addNewPoint(firstIndex, secondIndex);
        }
      }
    }

    _routes += _backtrackTable[0][0].normalizedRoutes();
    for (int row = 1; row <= rowCount; row++) {
      _routes += _backtrackTable[row][0].normalizedRoutes();
    }
    for (int column = 1; column <= rowCount; column++) {
      _routes += _backtrackTable[0][column].normalizedRoutes();
    }
  }

  List<BacktrackRoute> getCommonIndex() {
    return _routes;
  }
}
