import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';

class SentenceSegmentList {
  final List<SentenceSegment> list;

  SentenceSegmentList(this.list) {
    assert(!has2ConseqentEmpty());
  }

  bool has2ConseqentEmpty() {
    for (int index = 0; index < list.length - 1; index++) {
      if (list[index].word == "" || list[index + 1].word == "") {
        return true;
      }
    }
    return false;
  }

  SentenceSegmentList copyWith({
    SentenceSegmentList? sentenceSegmentList,
  }) {
    return SentenceSegmentList(
      sentenceSegmentList?.list.map((SentenceSegment sentenceSegment) => sentenceSegment.copyWith()).toList() ?? list,
    );
  }

  @override
  String toString() {
    return list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SentenceSegmentList) return false;
    if (list.length != other.list.length) return false;
    return list.asMap().entries.every((MapEntry<int, SentenceSegment> entry) {
      int index = entry.key;
      SentenceSegment timingPoint = entry.value;
      return timingPoint == other.list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(list);
}
