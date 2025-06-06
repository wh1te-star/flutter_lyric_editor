import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/relative_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/timing_index.dart';

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
    return _list.map((Timing timing) {
      return timing.caretPosition;
    }).isSorted((CaretPosition left, CaretPosition right) => left.compareTo(right));
  }

  bool isSeekPositionOrdered() {
    return _list.map((Timing timing) {
      return timing.seekPosition;
    }).isSorted((RelativeSeekPosition left, RelativeSeekPosition right) => left.compareTo(right));
  }

  bool isCharPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (Timing timing) => timing.caretPosition,
    ).values.every((List<Timing> group) => group.length <= charPositionDuplicationAllowed);
  }

  bool isSeekPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (Timing timing) => timing.seekPosition,
    ).values.every((List<Timing> group) => group.length <= seekPositionDuplicationAllowed);
  }

  static TimingList get empty => TimingList([]);
  bool get isEmpty => list.isEmpty;

  int get length => list.length;
  Timing operator [](TimingIndex index) => list[index.index];
  void operator []=(TimingIndex index, Timing value) {
    list[index.index] = value;
  }

  WordList toWordList(String sentence) {
    List<Word> newWordlist = [];
    for (int index = 0; index < list.length - 1; index++) {
      Timing leftTiming = list[index];
      Timing rightTiming = list[index + 1];
      String word = sentence.substring(
        leftTiming.caretPosition.position,
        rightTiming.caretPosition.position,
      );
      AbsoluteSeekPosition leftAbsolute = leftTiming.seekPosition.absolute;
      AbsoluteSeekPosition rightAbsolute = rightTiming.seekPosition.absolute;
      Duration duration = leftAbsolute.durationUntil(rightAbsolute);
      newWordlist.add(Word(word, duration));
    }

    return WordList(newWordlist);
  }

  TimingList copyWith({
    TimingList? timingList,
  }) {
    return TimingList(
      timingList?._list.map((Timing timing) => timing.copyWith()).toList() ?? _list,
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
      Timing timing = entry.value;
      return timing == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
