import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class ReadingMap {
  Map<PhrasePosition, Reading> readingMap;

  ReadingMap(this.readingMap);

  static ReadingMap get empty => ReadingMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<PhrasePosition, Reading>> get entries => map.entries;
  Iterable<PhrasePosition> get keys => map.keys;
  Iterable<Reading> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(PhrasePosition key) => map.containsKey(key);
  Reading? operator [](PhrasePosition key) => map[key];
  void operator []=(PhrasePosition key, Reading value) {
    map[key] = value;
  }

  Map<PhrasePosition, Reading> get map => readingMap;

  ReadingMap concatenate(int carryUp, ReadingMap other) {
    Map<PhrasePosition, Reading> newMap = Map<PhrasePosition, Reading>.from(readingMap);
    for (MapEntry<PhrasePosition, Reading> entry in other.readingMap.entries) {
      PhrasePosition segmentRange = entry.key;
      Reading reading = entry.value;
      PhrasePosition newSegmentRange = PhrasePosition(segmentRange.startIndex + carryUp, segmentRange.endIndex + carryUp);
      newMap[newSegmentRange] = reading;
    }
    return ReadingMap(newMap);
  }

  ReadingMap copyWith({
    Map<PhrasePosition, Reading>? readingMap,
  }) {
    return ReadingMap(
      readingMap ?? this.readingMap,
    );
  }

  @override
  String toString() {
    return readingMap.entries.map((MapEntry<PhrasePosition, Reading> readingMapEntry) => '${readingMapEntry.key}: ${readingMapEntry.value}').join("\n");
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
