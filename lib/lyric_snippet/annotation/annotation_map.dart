import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';

class AnnotationMap {
  Map<SegmentRange, Annotation> annotationMap;

  AnnotationMap(this.annotationMap);

  static AnnotationMap get emptyMap => AnnotationMap({});

  @override
  String toString() {
    return annotationMap.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimingPointList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, TimingPoint> entry) {
      int index = entry.key;
      TimingPoint timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
