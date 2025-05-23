import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class Sentence {
  final VocalistID vocalistID;
  final Timetable timetable;
  final RubyMap rubyMap;

  Sentence({
    required this.vocalistID,
    required this.timetable,
    required this.rubyMap,
  });

  static Sentence get empty => Sentence(
        vocalistID: VocalistID(0),
        timetable: Timetable.empty,
        rubyMap: RubyMap.empty,
      );
  bool get isEmpty => vocalistID.id == 0 && timetable.startTimestamp.isEmpty && timetable.isEmpty;

  String get sentence => timetable.sentence;
  SeekPosition get startTimestamp => timetable.startTimestamp;
  SeekPosition get endTimestamp => timetable.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timetable.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timetable.timingPointList.list;
  int get charLength => timetable.charLength;
  int get segmentLength => timetable.segmentLength;
  SentenceSegmentIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timetable.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timetable.getInsertionPositionInfo(insertionPosition);
  double getSegmentProgress(SeekPosition seekPosition) => timetable.getSegmentProgress(seekPosition);
  SentenceSegmentList getSentenceSegmentList(PhrasePosition phrasePosition) => timetable.getSentenceSegmentList(phrasePosition);
  TimingPointIndex leftTimingPointIndex(SentenceSegmentIndex segmentIndex) => timetable.leftTimingPointIndex(segmentIndex);
  TimingPointIndex rightTimingPointIndex(SentenceSegmentIndex segmentIndex) => timetable.rightTimingPointIndex(segmentIndex);
  TimingPoint leftTimingPoint(SentenceSegmentIndex segmentIndex) => timetable.leftTimingPoint(segmentIndex);
  TimingPoint rightTimingPoint(SentenceSegmentIndex segmentIndex) => timetable.rightTimingPoint(segmentIndex);

  MapEntry<PhrasePosition, Ruby> getRubyWords(SentenceSegmentIndex index) {
    return rubyMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(PhrasePosition.empty, Ruby.empty),
    );
  }

  PhrasePosition getRubysPhrasePositionFromSeekPosition(SeekPosition seekPosition) {
    for (MapEntry<PhrasePosition, Ruby> entry in rubyMap.map.entries) {
      PhrasePosition phrasePosition = entry.key;
      Ruby ruby = entry.value;
      SeekPosition startTimestamp = timetable.startTimestamp;
      List<TimingPoint> timingPoints = timetable.timingPointList.list;
      List<TimingPoint> rubyTimingPoints = ruby.timetable.timingPointList.list;
      SeekPosition rubyStartSeekPosition = SeekPosition(startTimestamp.position + timingPoints[phrasePosition.startIndex.index].seekPosition.position);
      SeekPosition startSeekPosition = SeekPosition(rubyStartSeekPosition.position + rubyTimingPoints.first.seekPosition.position);
      SeekPosition endSeekPosition = SeekPosition(rubyStartSeekPosition.position + rubyTimingPoints.last.seekPosition.position);
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return phrasePosition;
      }
    }
    return PhrasePosition.empty;
  }

  Sentence editSentence(String newSentence) {
    Timetable copiedTimetable = timetable.copyWith();
    copiedTimetable = copiedTimetable.editSentence(newSentence);
    return Sentence(vocalistID: vocalistID, timetable: copiedTimetable, rubyMap: rubyMap);
  }

  Sentence addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    RubyMap rubyMap = carryUpRubySegments(charPosition);
    Timetable timetable = this.timetable.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeTimingPoint(InsertionPosition charPosition, Option option) {
    RubyMap rubyMap = carryDownRubySegments(charPosition);
    Timetable timetable = this.timetable.deleteTimingPoint(charPosition, option);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence addRubyTimingPoint(PhrasePosition phrasePosition, InsertionPosition charPosition, SeekPosition seekPosition) {
    Timetable timetable = rubyMap[phrasePosition]!.timetable.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeRubyTimingPoint(PhrasePosition phrasePosition, InsertionPosition charPosition, Option option) {
    Timetable timetable = rubyMap[phrasePosition]!.timetable.deleteTimingPoint(charPosition, option);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence addRuby(PhrasePosition phrasePosition, String rubyString) {
    RubyMap rubyMap = this.rubyMap;
    SeekPosition rubyStartTimestamp = SeekPosition(startTimestamp.position + timingPoints[phrasePosition.startIndex.index].seekPosition.position);
    SeekPosition rubyEndTimestamp = SeekPosition(startTimestamp.position + timingPoints[phrasePosition.endIndex.index + 1].seekPosition.position);
    Duration rubyDuration = Duration(milliseconds: rubyEndTimestamp.position - rubyStartTimestamp.position);
    SentenceSegment sentenceSegment = SentenceSegment(rubyString, rubyDuration);
    Timetable timetable = Timetable(
      startTimestamp: rubyStartTimestamp,
      sentenceSegmentList: SentenceSegmentList([sentenceSegment]),
    );
    rubyMap.map[phrasePosition] = Ruby(timetable: timetable);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeRuby(PhrasePosition phrasePosition) {
    RubyMap rubyMap = this.rubyMap;
    rubyMap.map.remove(phrasePosition);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence manipulateSentence(SeekPosition seekPosition, SentenceEdge sentenceEdge, bool holdLength) {
    Timetable newTimetable = timetable.copyWith();
    newTimetable = newTimetable.manipulateTimetable(seekPosition, sentenceEdge, holdLength);
    return Sentence(vocalistID: vocalistID, timetable: newTimetable, rubyMap: rubyMap);
  }

  Tuple2<Sentence, Sentence> divideSentence(InsertionPosition charPosition, SeekPosition seekPosition) {
    String formerString = sentence.substring(0, charPosition.position);
    String latterString = sentence.substring(charPosition.position);
    Sentence sentence1 = Sentence.empty;
    Sentence sentence2 = Sentence.empty;

    if (formerString.isNotEmpty) {
      Timetable newTimetable = timetable.copyWith();
      newTimetable = newTimetable.addTimingPoint(charPosition, seekPosition);
      sentence1 = Sentence(
        vocalistID: vocalistID,
        timetable: newTimetable,
        rubyMap: rubyMap,
      );
    }

    if (latterString.isNotEmpty) {
      Timetable newTimetable = timetable.copyWith();
      newTimetable = newTimetable.addTimingPoint(charPosition, seekPosition);
      sentence2 = Sentence(
        vocalistID: vocalistID,
        timetable: newTimetable,
        rubyMap: rubyMap,
      );
    }

    return Tuple2(sentence1, sentence2);
  }

  RubyMap carryUpRubySegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timetable.getInsertionPositionInfo(insertionPosition)!;
    Map<PhrasePosition, Ruby> updatedRubys = {};

    rubyMap.map.forEach((PhrasePosition key, Ruby value) {
      PhrasePosition newKey = key.copyWith();

      switch (info) {
        case SentenceSegmentInsertionPositionInfo():
          SentenceSegmentIndex index = info.sentenceSegmentIndex;
          if (index < key.startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index <= key.endIndex) {
            newKey.endIndex++;
          }
          break;

        case TimingPointInsertionPositionInfo():
          TimingPointIndex index = info.timingPointIndex;
          TimingPointIndex startIndex = timetable.leftTimingPointIndex(key.startIndex);
          TimingPointIndex endIndex = timetable.rightTimingPointIndex(key.endIndex);
          if (index <= startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index < endIndex) {
            newKey.endIndex++;
          }
          break;

        default:
          assert(false, "An unexpected state occurred for the insertion position info");
      }

      updatedRubys[newKey] = value;
    });

    return RubyMap(updatedRubys);
  }

  RubyMap carryDownRubySegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timetable.getInsertionPositionInfo(insertionPosition)!;
    Map<PhrasePosition, Ruby> updatedRubys = {};
    int index = -1;
    if (info is SentenceSegmentInsertionPositionInfo) {
      index = info.sentenceSegmentIndex.index;
    } else if (info is TimingPointInsertionPositionInfo) {
      index = info.timingPointIndex.index;
    } else {
      assert(false, "An unexpected state was occurred for the insertion position");
    }

    rubyMap.map.forEach((PhrasePosition key, Ruby value) {
      PhrasePosition newKey = key.copyWith();
      int startIndex = key.startIndex.index;
      int endIndex = key.endIndex.index + 1;
      if (index == startIndex && index == endIndex + 1) {
        if (info is TimingPointInsertionPositionInfo && info.duplicate) {
          newKey.startIndex--;
          newKey.endIndex--;
        } else {
          return;
        }
      } else if (index < startIndex) {
        newKey.startIndex--;
        newKey.endIndex--;
      } else if (index < endIndex) {
        newKey.endIndex--;
      }
      updatedRubys[newKey] = value;
    });

    return RubyMap(updatedRubys);
  }

  List<Tuple2<PhrasePosition, Ruby?>> getRubysPhrasePositionList() {
    if (rubyMap.isEmpty) {
      SentenceSegmentIndex startIndex = SentenceSegmentIndex(0);
      SentenceSegmentIndex endIndex = SentenceSegmentIndex(sentenceSegments.length - 1);
      return [
        Tuple2(
          PhrasePosition(startIndex, endIndex),
          null,
        ),
      ];
    }

    List<Tuple2<PhrasePosition, Ruby?>> phrasePositionList = [];
    int previousEnd = -1;

    for (MapEntry<PhrasePosition, Ruby> entry in rubyMap.entries) {
      PhrasePosition phrasePosition = entry.key;
      Ruby ruby = entry.value;

      if (previousEnd + 1 <= phrasePosition.startIndex.index - 1) {
        SentenceSegmentIndex startIndex = SentenceSegmentIndex(previousEnd + 1);
        SentenceSegmentIndex endIndex = SentenceSegmentIndex(phrasePosition.startIndex.index - 1);
        phrasePositionList.add(
          Tuple2(
            PhrasePosition(startIndex, endIndex),
            null,
          ),
        );
      }
      phrasePositionList.add(
        Tuple2(
          phrasePosition,
          ruby,
        ),
      );

      previousEnd = phrasePosition.endIndex.index;
    }

    if (previousEnd + 1 <= sentenceSegments.length - 1) {
      SentenceSegmentIndex startIndex = SentenceSegmentIndex(previousEnd + 1);
      SentenceSegmentIndex endIndex = SentenceSegmentIndex(sentenceSegments.length - 1);
      phrasePositionList.add(
        Tuple2(
          PhrasePosition(startIndex, endIndex),
          null,
        ),
      );
    }

    return phrasePositionList;
  }

  Sentence copyWith({
    VocalistID? vocalistID,
    Timetable? timetable,
    RubyMap? rubyMap,
  }) {
    return Sentence(
      vocalistID: vocalistID ?? this.vocalistID,
      timetable: timetable ?? this.timetable,
      rubyMap: rubyMap ?? this.rubyMap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Sentence) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return vocalistID == other.vocalistID && timetable == other.timetable && rubyMap == other.rubyMap;
  }

  @override
  int get hashCode => vocalistID.hashCode ^ timetable.hashCode ^ rubyMap.hashCode;
}
