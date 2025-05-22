import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/position/segment_range.dart';

class ReadingMap {
  Map<Phrase, Reading> readingMap;

  ReadingMap(this.readingMap);

  static ReadingMap get empty => ReadingMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<Phrase, Reading>> get entries => map.entries;
  Iterable<Phrase> get keys => map.keys;
  Iterable<Reading> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(Phrase key) => map.containsKey(key);
  Reading? operator [](Phrase key) => map[key];
  void operator []=(Phrase key, Reading value) {
    map[key] = value;
  }

  Map<Phrase, Reading> get map => readingMap;

  ReadingMap concatenate(int carryUp, ReadingMap other) {
    Map<Phrase, Reading> newMap = Map<Phrase, Reading>.from(readingMap);
    for (MapEntry<Phrase, Reading> entry in other.readingMap.entries) {
      Phrase segmentRange = entry.key;
      Reading annotation = entry.value;
      Phrase newSegmentRange = Phrase(segmentRange.startIndex + carryUp, segmentRange.endIndex + carryUp);
      newMap[newSegmentRange] = annotation;
    }
    return ReadingMap(newMap);
  }

  ReadingMap copyWith({
    Map<Phrase, Reading>? annotationMap,
  }) {
    return ReadingMap(
      annotationMap ?? this.readingMap,
    );
  }

  @override
  String toString() {
    return readingMap.entries.map((MapEntry<Phrase, Reading> annotationMapEntry) => '${annotationMapEntry.key}: ${annotationMapEntry.value}').join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReadingMap) return false;
    return const DeepCollectionEquality().equals(readingMap, other.readingMap);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(readingMap);
}
