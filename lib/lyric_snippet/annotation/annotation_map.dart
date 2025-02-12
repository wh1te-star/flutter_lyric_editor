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
