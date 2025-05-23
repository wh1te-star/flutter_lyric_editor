import 'package:collection/collection.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/section/section.dart';

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
    }).isSorted((SeekPosition left, SeekPosition right) => left.compareTo(right));
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

  SectionList addSection(SeekPosition seekPosition) {
    List<Section> newList = List.from(list);
    if (!newList.contains(Section(seekPosition))) {
      newList.add(Section(seekPosition));
    }
    return SectionList(newList);
  }

  SectionList removeSection(SeekPosition seekPosition) {
    List<Section> newList = List.from(list);

    int targetIndex = 0;
    int minDistance = 3600000;
    for (int index = 0; index < newList.length; index++) {
      int distance = newList[index].seekPosition.position - seekPosition.position;
      if (distance < 0) {
        distance = -distance;
      }
      if (distance < minDistance) {
        minDistance = distance;
        targetIndex = index;
      }
    }

    if (minDistance < 5000) {
      newList.removeAt(targetIndex);
    }

    return SectionList(newList);
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
      Section timing = entry.value;
      return timing == other.list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(list);
}
