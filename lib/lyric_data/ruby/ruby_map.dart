import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class AnnotationMap {
  Map<PhrasePosition, Annotation> annotationMap;

  AnnotationMap(this.annotationMap);

  static AnnotationMap get empty => AnnotationMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<PhrasePosition, Annotation>> get entries => map.entries;
  Iterable<PhrasePosition> get keys => map.keys;
  Iterable<Annotation> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(PhrasePosition key) => map.containsKey(key);
  Annotation? operator [](PhrasePosition key) => map[key];
  void operator []=(PhrasePosition key, Annotation value) {
    map[key] = value;
  }

  Map<PhrasePosition, Annotation> get map => annotationMap;

  AnnotationMap concatenate(int carryUp, AnnotationMap other) {
    Map<PhrasePosition, Annotation> newMap = Map<PhrasePosition, Annotation>.from(annotationMap);
    for (MapEntry<PhrasePosition, Annotation> entry in other.annotationMap.entries) {
      PhrasePosition phrasePosition = entry.key;
      Annotation annotation = entry.value;
      PhrasePosition newPhrasePosition = PhrasePosition(phrasePosition.startIndex + carryUp, phrasePosition.endIndex + carryUp);
      newMap[newPhrasePosition] = annotation;
    }
    return AnnotationMap(newMap);
  }

  AnnotationMap copyWith({
    Map<PhrasePosition, Annotation>? annotationMap,
  }) {
    return AnnotationMap(
      annotationMap ?? this.annotationMap,
    );
  }

  @override
  String toString() {
    return annotationMap.entries.map((MapEntry<PhrasePosition, Annotation> annotationMapEntry) => '${annotationMapEntry.key}: ${annotationMapEntry.value}').join("\n");
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
