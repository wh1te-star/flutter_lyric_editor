import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';

class LyricSnippetList {
  final List<LyricSnippet> _lyricSnippetList;

  LyricSnippetList(this._lyricSnippetList);

  List<LyricSnippet> get list => _lyricSnippetList;

  bool isLyricSnippetsOrdered() {
    return list.map((LyricSnippet lyricSnippet) {
      return lyricSnippet.timing.startTimestamp;
    }).isSorted((int left, int right) => left.compareTo(right));
  }

  LyricSnippetList copyWith({
    LyricSnippetList? lyricSnippetList,
  }) {
    return LyricSnippetList(
      lyricSnippetList?.list.map((LyricSnippet lyricSnippet) => lyricSnippet.copyWith()).toList() ?? list,
    );
  }

  @override
  String toString() {
    return list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LyricSnippetList) return false;
    if (list.length != other.list.length) return false;
    return list.asMap().entries.every((MapEntry<int, LyricSnippet> entry) {
      int index = entry.key;
      LyricSnippet timingPoint = entry.value;
      return timingPoint == other.list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(list);
}
