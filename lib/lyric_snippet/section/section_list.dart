import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/section/section.dart';

class SectionList {
  final int seekPositionDuplicationAllowed = 1;
  final List<Section> _list;

  SectionList(this._list) {
    assert(isSeekPositionOrdered());
    assert(isSeekPositionDuplicationAllowed());
  }

  List<Section> get list => _list;

  bool isSeekPositionOrdered() {
    return list.map((Section section) {
      return section.seekPosition;
    }).isSorted((int left, int right) => left.compareTo(right));
  }

  bool isSeekPositionDuplicationAllowed() {
    return groupBy(
      list,
      (Section section) => section.seekPosition,
    ).values.every((List<Section> group) => group.length <= seekPositionDuplicationAllowed);
  }

  static SectionList get empty => SectionList([]);
  bool get isEmpty => list.isEmpty;

  Section operator [](int index) => list[index];
  void operator []=(int index, Section value) {
    list[index] = value;
  }

  SectionList copyWith({
    SectionList? sectionList,
  }) {
    return SectionList(
      sectionList?.list.map((Section section) => section.copyWith()).toList() ?? list,
    );
  }

  @override
  String toString() {
    return list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SectionList) return false;
    if (list.length != other.list.length) return false;
    return list.asMap().entries.every((MapEntry<int, Section> entry) {
      int index = entry.key;
      Section timingPoint = entry.value;
      return timingPoint == other.list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(list);
}
