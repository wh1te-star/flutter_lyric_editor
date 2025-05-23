import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class Ruby {
  Timetable timetable;

  Ruby({
    required this.timetable,
  });

  static Ruby get empty {
    return Ruby(
      timetable: Timetable.empty,
    );
  }

  bool isEmpty() {
    return timetable.isEmpty;
  }

  String get sentence => timetable.sentence;
  SeekPosition get startTimestamp => timetable.startTimestamp;
  SeekPosition get endTimestamp => timetable.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timetable.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timetable.timingPointList.list;
  SentenceSegmentIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timetable.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timetable.getInsertionPositionInfo(insertionPosition);
  SentenceSegmentList getSentenceSegmentList(PhrasePosition phrasePosition) => timetable.getSentenceSegmentList(phrasePosition);

  Ruby copyWith({
    Timetable? timetable,
  }) {
    return Ruby(
      timetable: timetable ?? this.timetable,
    );
  }

  @override
  String toString() {
    return "Ruby($timetable)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Ruby) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return timetable == other.timetable;
  }

  @override
  int get hashCode => timetable.hashCode;
}
