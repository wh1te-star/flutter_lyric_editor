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
  final Timing timing;
  final RubyMap rubyMap;

  Sentence({
    required this.vocalistID,
    required this.timing,
    required this.rubyMap,
  });

  static Sentence get empty => Sentence(
        vocalistID: VocalistID(0),
        timing: Timing.empty,
        rubyMap: RubyMap.empty,
      );
  bool get isEmpty => vocalistID.id == 0 && timing.startTimestamp.isEmpty && timing.isEmpty;

  String get sentence => timing.sentence;
  SeekPosition get startTimestamp => timing.startTimestamp;
  SeekPosition get endTimestamp => timing.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timing.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timing.timingPointList.list;
  int get charLength => timing.charLength;
  int get segmentLength => timing.segmentLength;
  SentenceSegmentIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timing.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timing.getInsertionPositionInfo(insertionPosition);
  double getSegmentProgress(SeekPosition seekPosition) => timing.getSegmentProgress(seekPosition);
  SentenceSegmentList getSentenceSegmentList(PhrasePosition phrasePosition) => timing.getSentenceSegmentList(phrasePosition);
  TimingPointIndex leftTimingPointIndex(SentenceSegmentIndex segmentIndex) => timing.leftTimingPointIndex(segmentIndex);
  TimingPointIndex rightTimingPointIndex(SentenceSegmentIndex segmentIndex) => timing.rightTimingPointIndex(segmentIndex);
  TimingPoint leftTimingPoint(SentenceSegmentIndex segmentIndex) => timing.leftTimingPoint(segmentIndex);
  TimingPoint rightTimingPoint(SentenceSegmentIndex segmentIndex) => timing.rightTimingPoint(segmentIndex);

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
      SeekPosition startTimestamp = timing.startTimestamp;
      List<TimingPoint> timingPoints = timing.timingPointList.list;
      List<TimingPoint> rubyTimingPoints = ruby.timing.timingPointList.list;
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
    Timing copiedTiming = timing.copyWith();
    copiedTiming = copiedTiming.editSentence(newSentence);
    return Sentence(vocalistID: vocalistID, timing: copiedTiming, rubyMap: rubyMap);
  }

  Sentence addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    RubyMap rubyMap = carryUpRubySegments(charPosition);
    Timing timing = this.timing.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence removeTimingPoint(InsertionPosition charPosition, Option option) {
    RubyMap rubyMap = carryDownRubySegments(charPosition);
    Timing timing = this.timing.deleteTimingPoint(charPosition, option);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence addRubyTimingPoint(PhrasePosition phrasePosition, InsertionPosition charPosition, SeekPosition seekPosition) {
    Timing timing = rubyMap[phrasePosition]!.timing.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence removeRubyTimingPoint(PhrasePosition phrasePosition, InsertionPosition charPosition, Option option) {
    Timing timing = rubyMap[phrasePosition]!.timing.deleteTimingPoint(charPosition, option);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence addRuby(PhrasePosition phrasePosition, String rubyString) {
    RubyMap rubyMap = this.rubyMap;
    SeekPosition rubyStartTimestamp = SeekPosition(startTimestamp.position + timingPoints[phrasePosition.startIndex.index].seekPosition.position);
    SeekPosition rubyEndTimestamp = SeekPosition(startTimestamp.position + timingPoints[phrasePosition.endIndex.index + 1].seekPosition.position);
    Duration rubyDuration = Duration(milliseconds: rubyEndTimestamp.position - rubyStartTimestamp.position);
    SentenceSegment sentenceSegment = SentenceSegment(rubyString, rubyDuration);
    Timing timing = Timing(
      startTimestamp: rubyStartTimestamp,
      sentenceSegmentList: SentenceSegmentList([sentenceSegment]),
    );
    rubyMap.map[phrasePosition] = Ruby(timing: timing);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence removeRuby(PhrasePosition phrasePosition) {
    RubyMap rubyMap = this.rubyMap;
    rubyMap.map.remove(phrasePosition);
    return Sentence(vocalistID: vocalistID, timing: timing, rubyMap: rubyMap);
  }

  Sentence manipulateSentence(SeekPosition seekPosition, SentenceEdge sentenceEdge, bool holdLength) {
    Timing newTiming = timing.copyWith();
    newTiming = newTiming.manipulateTiming(seekPosition, sentenceEdge, holdLength);
    return Sentence(vocalistID: vocalistID, timing: newTiming, rubyMap: rubyMap);
  }

  Tuple2<Sentence, Sentence> divideSentence(InsertionPosition charPosition, SeekPosition seekPosition) {
    String formerString = sentence.substring(0, charPosition.position);
    String latterString = sentence.substring(charPosition.position);
    Sentence sentence1 = Sentence.empty;
    Sentence sentence2 = Sentence.empty;

    if (formerString.isNotEmpty) {
      Timing newTiming = timing.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      sentence1 = Sentence(
        vocalistID: vocalistID,
        timing: newTiming,
        rubyMap: rubyMap,
      );
    }

    if (latterString.isNotEmpty) {
      Timing newTiming = timing.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      sentence2 = Sentence(
        vocalistID: vocalistID,
        timing: newTiming,
        rubyMap: rubyMap,
      );
    }

    return Tuple2(sentence1, sentence2);
  }

  RubyMap carryUpRubySegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timing.getInsertionPositionInfo(insertionPosition)!;
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
          TimingPointIndex startIndex = timing.leftTimingPointIndex(key.startIndex);
          TimingPointIndex endIndex = timing.rightTimingPointIndex(key.endIndex);
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
    InsertionPositionInfo info = timing.getInsertionPositionInfo(insertionPosition)!;
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
    Timing? timing,
    RubyMap? rubyMap,
  }) {
    return Sentence(
      vocalistID: vocalistID ?? this.vocalistID,
      timing: timing ?? this.timing,
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
    return vocalistID == other.vocalistID && timing == other.timing && rubyMap == other.rubyMap;
  }

  @override
  int get hashCode => vocalistID.hashCode ^ timing.hashCode ^ rubyMap.hashCode;
}
