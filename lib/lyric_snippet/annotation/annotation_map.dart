import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';

class AnnotationMap {
  Map<SegmentRange, Annotation> annotationMap;

  AnnotationMap(this.annotationMap);

  static AnnotationMap get emptyMap => AnnotationMap({});

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
