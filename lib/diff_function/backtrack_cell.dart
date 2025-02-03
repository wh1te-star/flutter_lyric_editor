import 'package:flutter/services.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

class BacktrackTable {
  LongestCommonSequence lcm;
  List<BacktrackRoute> routes = [];

  BacktrackTable({required this.lcm}) {
    establishRoute();
  }

  void establishRoute() {
    int rowCount = lcm.firstStr.length;
    int columnCount = lcm.secondStr.length;
    List<List<BacktrackCell>> backtrackTable = List.generate(
      rowCount + 1,
      (_) => List.generate(
        columnCount + 1,
        (_) => BacktrackCell([]),
      ),
    );
    backtrackTable[rowCount][columnCount].routes = [BacktrackRoute.dummyRoute()];

    for (int firstIndex = rowCount; firstIndex >= 0; firstIndex--) {
      for (int secondIndex = columnCount; secondIndex >= 0; secondIndex--) {
        LCMCell lcmCell = lcm.cell(firstIndex, secondIndex);
        BacktrackCell backtrackCell = backtrackTable[firstIndex][secondIndex];
        if (lcmCell.fromLeft) {
          BacktrackCell previousBacktrackCell = backtrackTable[firstIndex][secondIndex + 1];
          backtrackCell.routes += previousBacktrackCell.routes;
        }
        if (lcmCell.fromUpper) {
          BacktrackCell previousBacktrackCell = backtrackTable[firstIndex + 1][secondIndex];
          backtrackCell.routes += previousBacktrackCell.routes;
        }
        if (lcmCell.fromLeftUpper) {
          BacktrackCell previousBacktrackCell = backtrackTable[firstIndex + 1][secondIndex + 1];
          BacktrackCell appendedRoutes = BacktrackCell(
            previousBacktrackCell.routes.map((BacktrackRoute route) {
              BacktrackRoute appendedRoute = route;
              appendedRoute.points.add(BacktrackPoint(firstIndex, secondIndex));
              return appendedRoute;
            }).toList(),
          );
          backtrackCell = appendedRoutes;
        }
      }
    }

    routes = backtrackTable[0][0].routes;
    for (int row = 1; row <= rowCount; row++) {
      routes += backtrackTable[row][0].routes;
    }
    for (int column = 1; column <= rowCount; column++) {
      routes += backtrackTable[0][column].routes;
    }
  }
}

class BacktrackCell {
  List<BacktrackRoute> routes = [];

  BacktrackCell(this.routes);
}

class BacktrackRoute {
  List<BacktrackPoint> points = [];

  BacktrackRoute(this.points);

  static BacktrackRoute dummyRoute() => BacktrackRoute([BacktrackPoint.dummyPoint()]);
}

class BacktrackPoint {
  int row;
  int column;

  BacktrackPoint(this.row, this.column) {
    if (row != -1 || column != -1) {
      assert(row >= 0);
      assert(column >= 0);
    }
  }

  static BacktrackPoint dummyPoint() => BacktrackPoint(-1, -1);
}
