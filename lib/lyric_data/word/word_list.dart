import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class WordList {
  final List<Word> _list;

  WordList(this._list) {
    assert(!has2ConseqentEmpty());
  }

  List<Word> get list => _list;

  static WordList get empty => WordList([]);
  bool get isEmpty => list.isEmpty;

  int get length => list.length;
  Word operator [](int index) => list[index];
  void operator []=(int index, Word value) {
    list[index] = value;
  }

  String get sentence {
    return _list.map((Word segment) {
      return segment.word;
    }).join("");
  }

  int get segmentLength => list.length;
  int get charLength {
    return list.fold(0, (total, sentenceSegment) {
      return total + sentenceSegment.word.length;
    });
  }

  bool has2ConseqentEmpty() {
    for (int index = 0; index < _list.length - 1; index++) {
      if (_list[index].word == "" && _list[index + 1].word == "") {
        return true;
      }
    }
    return false;
  }

  TimingList toTimingPointList() {
    List<TimingPoint> timingPoints = [];
    InsertionPosition insertionPosition = InsertionPosition(0);
    SeekPosition seekPosition = SeekPosition(0);
    for (Word sentenceSegment in list) {
      timingPoints.add(TimingPoint(insertionPosition, seekPosition));

      insertionPosition += sentenceSegment.word.length;
      seekPosition += sentenceSegment.duration;
    }
    timingPoints.add(TimingPoint(insertionPosition, seekPosition));

    return TimingList(timingPoints);
  }

  WordList copyWith({
    WordList? sentenceSegmentList,
  }) {
    return WordList(
      sentenceSegmentList?._list.map((Word sentenceSegment) => sentenceSegment.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  WordList operator +(WordList other) {
    List<Word> combinedList = [..._list, ...other._list];
    return WordList(combinedList);
  }

  WordList addSegment(Word segment) {
    List<Word> combinedList = [..._list, segment];
    return WordList(combinedList);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, Word> entry) {
      int index = entry.key;
      Word timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
