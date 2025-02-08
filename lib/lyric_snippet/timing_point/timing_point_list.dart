import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';

class TimingPointList {
  final List<TimingPoint> list;

  TimingPointList(this.list);

  /*
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
  */
}
