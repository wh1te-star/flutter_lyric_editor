import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';
import 'package:lyric_editor/diff_function/lcs_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

class BacktrackTable {
  final LongestCommonSequence _lcs;
  List<List<BacktrackCell>> _backtrackTable = [];
  List<BacktrackRoute> _routes = [];

  BacktrackTable({required LongestCommonSequence lcs}) : _lcs = lcs {
    foundRoute();
  }

  void foundRoute() {
    initBacktrackTable();

    fillBacktrackTable();

    _routes = normalizeFoundRoutes();
  }

  void initBacktrackTable() {
    int rowCount = _lcs.firstStr.length;
    int columnCount = _lcs.secondStr.length;
    _backtrackTable = List.generate(
      rowCount + 1,
      (rowIndex) => List.generate(
        columnCount + 1,
        (_) => BacktrackCell([]),
      ),
    );
  }

  void fillBacktrackTable() {
    int rowCount = _lcs.firstStr.length;
    int columnCount = _lcs.secondStr.length;

    _backtrackTable[rowCount][columnCount] = BacktrackCell([BacktrackRoute.dummyRoute()]);

    for (int firstIndex = rowCount; firstIndex >= 0; firstIndex--) {
      for (int secondIndex = columnCount; secondIndex >= 0; secondIndex--) {
        bool isLowerIn = firstIndex + 1 <= rowCount;
        bool isRightIn = secondIndex + 1 <= columnCount;

        if (isLowerIn && isRightIn) {
          LCSCell rightLowerLCSCell = _lcs.cell(firstIndex + 1, secondIndex + 1);
          if (rightLowerLCSCell.fromLeftUpper) {
            BacktrackCell newRoutes = _backtrackTable[firstIndex + 1][secondIndex + 1].addNewPoint(firstIndex, secondIndex);
            _backtrackTable[firstIndex][secondIndex] = newRoutes;
          }
        }

        if (isRightIn) {
          LCSCell rightLCSCell = _lcs.cell(firstIndex, secondIndex + 1);
          if (rightLCSCell.fromLeft) {
            BacktrackCell newRoutes = _backtrackTable[firstIndex][secondIndex + 1].inheritRoutes(_backtrackTable[firstIndex][secondIndex]);
            _backtrackTable[firstIndex][secondIndex] = newRoutes;
          }
        }

        if (isLowerIn) {
          LCSCell lowerLCSCell = _lcs.cell(firstIndex + 1, secondIndex);
          if (lowerLCSCell.fromUpper) {
            BacktrackCell newRoutes = _backtrackTable[firstIndex + 1][secondIndex].inheritRoutes(_backtrackTable[firstIndex][secondIndex]);
            _backtrackTable[firstIndex][secondIndex] = newRoutes;
          }
        }
      }
    }
  }

  List<BacktrackRoute> normalizeFoundRoutes() {
    int rowCount = _lcs.firstStr.length;
    int columnCount = _lcs.secondStr.length;
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
    int rowCount = _lcs.firstStr.length;
    int columnCount = _lcs.secondStr.length;
    String output = "";
    for (int row = 0; row <= rowCount; row++) {
      for (int column = 0; column <= columnCount; column++) {
        BacktrackCell backtrackCell = _backtrackTable[row][column];
        LCSCell lcsCell = _lcs.cell(row, column);
        output += "$lcsCell/${backtrackCell.routes.length}, ";
      }
      output += "\n";
    }
    return output;
  }
}
