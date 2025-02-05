import 'package:collection/collection.dart';
import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';

class BacktrackCell {
  final List<BacktrackRoute> _routes;

  BacktrackCell(this._routes);

  get routes => _routes;

  BacktrackCell inheritRoutes(BacktrackCell cell) {
    return copyWith(routes: [
      ..._routes.map((route) => route.copyWith()),
      ...cell._routes.where((route) => !_routes.contains(route)).map((route) => route.copyWith()),
    ]);
  }

  BacktrackCell addNewPoint(int firstIndex, int secondIndex) {
    return copyWith(routes: _routes.map((route) => route.copyWith(points: [...route.points, BacktrackPoint(firstIndex, secondIndex)])).toList());
  }

  List<BacktrackRoute> normalizedRoutes() {
    return _routes.map((BacktrackRoute route) {
      return route.normalize();
    }).toList();
  }

  BacktrackCell copyWith({
    List<BacktrackRoute>? routes,
  }) {
    return BacktrackCell(
      routes ?? _routes.map((route) => route.copyWith()).toList(),
    );
  }

  @override
  String toString() {
    return _routes.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BacktrackCell) return false;
    if (_routes.length != other._routes.length) return false;
    return _routes.asMap().entries.every((entry) {
      return entry.value == other._routes[entry.key];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_routes);
}
