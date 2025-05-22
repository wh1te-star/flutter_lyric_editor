import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class TimingList {
  static const charPositionDuplicationAllowed = 2;
  static const seekPositionDuplicationAllowed = 1;
  final List<Timing> _list;

  TimingList(this._list) {
    assert(isCharPositionOrdered());
    assert(isSeekPositionOrdered());
    assert(isCharPositionDuplicationAllowed());
    assert(isSeekPositionDuplicationAllowed());
  }

  List<Timing> get list => _list;

  bool isCharPositionOrdered() {
    return _list.map((Timing timingPoint) {
      return timingPoint.insertionPosition;
    }).isSorted((InsertionPosition left, InsertionPosition right) => left.compareTo(right));
  }

  bool isSeekPositionOrdered() {
    return _list.map((Timing timingPoint) {
      return timingPoint.seekPosition;
    }).isSorted((SeekPosition left, SeekPosition right) => left.compareTo(right));
  }

  bool isCharPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (Timing timingPoint) => timingPoint.insertionPosition,
    ).values.every((List<Timing> group) => group.length <= charPositionDuplicationAllowed);
  }

  bool isSeekPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (Timing timingPoint) => timingPoint.seekPosition,
    ).values.every((List<Timing> group) => group.length <= seekPositionDuplicationAllowed);
  }

  static TimingList get empty => TimingList([]);
  bool get isEmpty => list.isEmpty;

  int get length => list.length;
  Timing operator [](int index) => list[index];
  void operator []=(int index, Timing value) {
    list[index] = value;
  }

  WordList toWordList(String sentence) {
    List<Word> sentenceSegments = [];
    List<Timing> timingPoints = list;
    for (int index = 0; index < timingPoints.length - 1; index++) {
      String word = sentence.substring(
        timingPoints[index].insertionPosition.position,
        timingPoints[index + 1].insertionPosition.position,
      );
      Duration duration = Duration(
        milliseconds: timingPoints[index + 1].seekPosition.position - timingPoints[index].seekPosition.position,
      );
      sentenceSegments.add(Word(word, duration));
    }

    return WordList(sentenceSegments);
  }

  TimingList copyWith({
    TimingList? timingPointList,
  }) {
    return TimingList(
      timingPointList?._list.map((Timing timingPoint) => timingPoint.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimingList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, Timing> entry) {
      int index = entry.key;
      Timing timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
