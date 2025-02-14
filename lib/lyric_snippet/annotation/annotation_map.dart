import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';

class AnnotationMap {
  Map<SegmentRange, Annotation> annotationMap;

  AnnotationMap(this.annotationMap);

  static AnnotationMap get empty => AnnotationMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<SegmentRange, Annotation>> get entries => map.entries;
  Iterable<SegmentRange> get keys => map.keys;
  Iterable<Annotation> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(SegmentRange key) => map.containsKey(key);
  Annotation? operator [](SegmentRange key) => map[key];
  void operator []=(SegmentRange key, Annotation value) {
    map[key] = value;
  }

  Map<SegmentRange, Annotation> get map => annotationMap;

  AnnotationMap concatenate(int carryUp, AnnotationMap other) {
    Map<SegmentRange, Annotation> newMap = Map<SegmentRange, Annotation>.from(annotationMap);
    for (MapEntry<SegmentRange, Annotation> entry in other.annotationMap.entries) {
      SegmentRange segmentRange = entry.key;
      Annotation annotation = entry.value;
      SegmentRange newSegmentRange = SegmentRange(segmentRange.startIndex + carryUp, segmentRange.endIndex + carryUp);
      newMap[newSegmentRange] = annotation;
    }
    return AnnotationMap(newMap);
  }

  AnnotationMap copyWith({
    Map<SegmentRange, Annotation>? annotationMap,
  }) {
    return AnnotationMap(
      annotationMap ?? this.annotationMap,
    );
  }

  @override
  String toString() {
    return annotationMap.entries.map((MapEntry<SegmentRange, Annotation> annotationMapEntry) => '${annotationMapEntry.key}: ${annotationMapEntry.value}').join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnnotationMap) return false;
    return const DeepCollectionEquality().equals(annotationMap, other.annotationMap);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(annotationMap);
}
