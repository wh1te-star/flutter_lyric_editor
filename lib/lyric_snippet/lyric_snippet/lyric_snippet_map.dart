import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id_generator.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/timing_object.dart';

class LyricSnippetMap {
  final Map<LyricSnippetID, LyricSnippet> _lyricSnippetMap;
  final LyricSnippetIdGenerator idGenerator = LyricSnippetIdGenerator();

  LyricSnippetMap(this._lyricSnippetMap) {
    assert(isLyricSnippetsOrdered());
  }

  Map<LyricSnippetID, LyricSnippet> get map => _lyricSnippetMap;

  bool isLyricSnippetsOrdered() {
    return map.values.map((LyricSnippet lyricSnippet) {
      return lyricSnippet.timing.startTimestamp;
    }).isSorted((int left, int right) => left.compareTo(right));
  }

  static LyricSnippetMap get empty => LyricSnippetMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<LyricSnippetID, LyricSnippet>> get entries => map.entries;
  Iterable<LyricSnippetID> get keys => map.keys;
  Iterable<LyricSnippet> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(LyricSnippetID key) => map.containsKey(key);
  LyricSnippet? operator [](LyricSnippetID key) => map[key];
  void operator []=(LyricSnippetID key, LyricSnippet value) {
    map[key] = value;
  }

  LyricSnippetMap sortLyricSnippetList(LyricSnippetMap lyricSnippetMap) {
    return LyricSnippetMap(Map.fromEntries(
      lyricSnippetMap.map.entries.toList()
        ..sort(
          (a, b) {
            int compareStartTime = a.value.startTimestamp.compareTo(b.value.startTimestamp);
            if (compareStartTime != 0) {
              return compareStartTime;
            } else {
              return a.value.vocalistID.id.compareTo(b.value.vocalistID.id);
            }
          },
        ),
    ));
  }

  LyricSnippetMap addLyricSnippet(LyricSnippet lyricSnippet) {
    final Map<LyricSnippetID, LyricSnippet> newMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    newMap[idGenerator.idGen()] = lyricSnippet;
    return sortLyricSnippetList(LyricSnippetMap(newMap));
  }

  LyricSnippetMap removeVocalistByID(LyricSnippetID id) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    copiedMap.remove(id);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap getSnippetsAtSeekPosition({
    required int seekPosition,
    VocalistID? vocalistID,
    int startBulge = 0,
    int endBulge = 0,
  }) {
    final Iterable<MapEntry<LyricSnippetID, LyricSnippet>> filteredEntries = map.entries.where((MapEntry<LyricSnippetID, LyricSnippet> entry) {
      bool isWithinTimestamp = entry.value.startTimestamp - startBulge <= seekPosition && seekPosition <= entry.value.endTimestamp + endBulge;
      bool isMatchingVocalist = vocalistID == null || entry.value.vocalistID == vocalistID;
      return isWithinTimestamp && isMatchingVocalist;
    });

    return LyricSnippetMap(Map.fromEntries(filteredEntries));
  }

  LyricSnippetMap copyWith({
    Map<LyricSnippetID, LyricSnippet>? lyricSnippetMap,
  }) {
    return LyricSnippetMap({...(lyricSnippetMap ?? map)}.map((key, value) => MapEntry(key, value.copyWith())));
  }

  @override
  String toString() {
    return map.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LyricSnippetMap) return false;
    if (map.length != other.map.length) return false;
    return map.keys.every((key) {
      return map[key] == other.map[key];
    });
  }

  @override
  int get hashCode => map.entries.fold(0, (hash, entry) {
        return hash ^ entry.key.hashCode ^ entry.value.hashCode;
      });
}
