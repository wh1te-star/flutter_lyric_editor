import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/id_generator.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';

class LyricSnippetMap {
  final Map<LyricSnippetID, LyricSnippet> _lyricSnippetMap;

  LyricSnippetMap(this._lyricSnippetMap) {
    assert(isLyricSnippetsOrdered());
  }

  Map<LyricSnippetID, LyricSnippet> get map => _lyricSnippetMap;

  bool isLyricSnippetsOrdered() {
    return map.values.map((LyricSnippet lyricSnippet) {
      return lyricSnippet.timing.startTimestamp;
    }).isSorted((int left, int right) => left.compareTo(right));
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
