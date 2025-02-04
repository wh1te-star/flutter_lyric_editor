
import 'package:lyric_editor/diff_function/backtrack_point.dart';

class BacktrackRoute {
  List<BacktrackPoint> points = [];

  BacktrackRoute(this.points);

  static BacktrackRoute dummyRoute() => BacktrackRoute([BacktrackPoint.dummyPoint()]);
  
  BacktrackRoute normalize(){
    List<BacktrackPoint> routeWithoutDummy = points;
    routeWithoutDummy.removeAt(0);
    return BacktrackRoute(routeWithoutDummy.reversed.toList());
  }

  @override
  String toString() {
    return points.map((BacktrackPoint point) {
      return point.toString();
    }).join("->");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BacktrackRoute) return false;
    if (points.length != other.points.length) return false;
    return points.asMap().entries.every((entry) {
      return entry.value == other.points[entry.key];
    });
  }

  @override
  int get hashCode => points.fold(0, (prev, point) => prev ^ point.hashCode);
}