import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';


class BacktrackCell {
  List<BacktrackRoute> _routes = [];

  BacktrackCell(this._routes);

  BacktrackCell inheritRoutes(BacktrackCell cell) {
    BacktrackCell inheritedCell = BacktrackCell(_routes);
    for (BacktrackRoute route in cell._routes) {
      if (!inheritedCell._routes.contains(route)) {
        inheritedCell._routes.add(route);
      }
    }
    return inheritedCell;
  }

  BacktrackCell addNewPoint(int firstIndex, int secondIndex) {
    List<BacktrackRoute> appendedRoutes = _routes.map((BacktrackRoute route) {
      BacktrackRoute appendedRoute = route;
      appendedRoute.points.add(BacktrackPoint(firstIndex, secondIndex));
      return appendedRoute;
    }).toList();
    _routes += appendedRoutes;
    return BacktrackCell(appendedRoutes);
  }
  
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BacktrackCell) return false;
    if (_routes.length != other._routes.length) return false;
    return _routes.asMap().entries.every((entry) {
      return entry.value == other._routes[entry.key];
    });
  }
}

