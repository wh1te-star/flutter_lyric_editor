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

  static LyricSnippetMap get empty {
    return LyricSnippetMap({});
  }

  bool isEmpty() {
    return map.isEmpty;
  }

  LyricSnippetMap addVocalist(VocalistID vocalistID, Timing timing) {
    final Map<LyricSnippetID, LyricSnippet> newMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    newMap[idGenerator.idGen()] = LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: AnnotationMap({}));
    return LyricSnippetMap(newMap);
  }

  LyricSnippetMap removeVocalistByID(LyricSnippetID id) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    copiedMap.remove(id);
    return LyricSnippetMap(copiedMap);
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
