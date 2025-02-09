import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';

class SentenceSegmentList {
  final List<SentenceSegment> _list;

  SentenceSegmentList(this._list) {
    assert(!has2ConseqentEmpty());
  }

  List<SentenceSegment> get items => _list;

  String get sentence {
    return _list.map((SentenceSegment segment) {
      return segment.word;
    }).join("");
  }

  bool has2ConseqentEmpty() {
    for (int index = 0; index < _list.length - 1; index++) {
      if (_list[index].word == "" || _list[index + 1].word == "") {
        return true;
      }
    }
    return false;
  }

  SentenceSegmentList copyWith({
    SentenceSegmentList? sentenceSegmentList,
  }) {
    return SentenceSegmentList(
      sentenceSegmentList?._list.map((SentenceSegment sentenceSegment) => sentenceSegment.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SentenceSegmentList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, SentenceSegment> entry) {
      int index = entry.key;
      SentenceSegment timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
