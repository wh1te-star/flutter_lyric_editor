import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class Sentence {
  final VocalistID vocalistID;
  final Timeline timeline;
  final ReadingMap readingMap;

  Sentence({
    required this.vocalistID,
    required this.timeline,
    required this.readingMap,
  });

  static Sentence get empty => Sentence(
        vocalistID: VocalistID(0),
        timeline: Timeline.empty,
        readingMap: ReadingMap.empty,
      );
  bool get isEmpty => vocalistID.id == 0 && timeline.startTime.isEmpty && timeline.isEmpty;

  String get sentence => timeline.sentence;
  SeekPosition get startTimestamp => timeline.startTime;
  SeekPosition get endTimestamp => timeline.endTimestamp;
  List<Word> get sentenceSegments => timeline.wordList.list;
  List<Timing> get timingPoints => timeline.timingList.list;
  int get charLength => timeline.charCount;
  int get segmentLength => timeline.segmentCount;
  WordIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timeline.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timeline.getInsertionPositionInfo(insertionPosition);
  double getSegmentProgress(SeekPosition seekPosition) => timeline.getSegmentProgress(seekPosition);
  WordList getSentenceSegmentList(PhrasePosition segmentRange) => timeline.getSentenceSegmentList(segmentRange);
  TimingIndex leftTimingPointIndex(WordIndex segmentIndex) => timeline.leftTimingIndex(segmentIndex);
  TimingIndex rightTimingPointIndex(WordIndex segmentIndex) => timeline.rightTimingIndex(segmentIndex);
  Timing leftTimingPoint(WordIndex segmentIndex) => timeline.leftTiming(segmentIndex);
  Timing rightTimingPoint(WordIndex segmentIndex) => timeline.rightTiming(segmentIndex);

  MapEntry<PhrasePosition, Reading> getReadingWords(WordIndex index) {
    return readingMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(PhrasePosition.empty, Reading.empty),
    );
  }

  PhrasePosition getPhraseFromSeekPosition(SeekPosition seekPosition) {
    for (MapEntry<PhrasePosition, Reading> entry in readingMap.map.entries) {
      PhrasePosition range = entry.key;
      Reading reading = entry.value;
      SeekPosition startTimestamp = timeline.startTime;
      List<Timing> timingPoints = timeline.timingList.list;
      List<Timing> readingTimings = reading.timeline.timingList.list;
      SeekPosition readingStartSeekPosition = SeekPosition(startTimestamp.position + timingPoints[range.startIndex.index].seekPosition.position);
      SeekPosition startSeekPosition = SeekPosition(readingStartSeekPosition.position + readingTimings.first.seekPosition.position);
      SeekPosition endSeekPosition = SeekPosition(readingStartSeekPosition.position + readingTimings.last.seekPosition.position);
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range;
      }
    }
    return PhrasePosition.empty;
  }

  Sentence editSentence(String newSentence) {
    Timeline copiedTiming = timeline.copyWith();
    copiedTiming = copiedTiming.editSentence(newSentence);
    return Sentence(vocalistID: vocalistID, timeline: copiedTiming, readingMap: readingMap);
  }

  Sentence addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    ReadingMap readingMap = carryUpReadingPhrases(charPosition);
    Timeline timing = this.timeline.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence removeTimingPoint(InsertionPosition charPosition, Option option) {
    ReadingMap readingMap = carryDownReadingPhrase(charPosition);
    Timeline timing = this.timeline.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence addReadingTiming(PhrasePosition segmentRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    Timeline timing = readingMap[segmentRange]!.timeline.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence removeReadingTiming(PhrasePosition segmentRange, InsertionPosition charPosition, Option option) {
    Timeline timing = readingMap[segmentRange]!.timeline.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence addReading(PhrasePosition segmentRange, String readingString) {
    ReadingMap readingMap = this.readingMap;
    SeekPosition readingStartTime = SeekPosition(startTimestamp.position + timingPoints[segmentRange.startIndex.index].seekPosition.position);
    SeekPosition readingEndTime = SeekPosition(startTimestamp.position + timingPoints[segmentRange.endIndex.index + 1].seekPosition.position);
    Duration readingDuration = Duration(milliseconds: readingEndTime.position - readingStartTime.position);
    Word sentenceSegment = Word(readingString, readingDuration);
    Timeline timing = Timeline(
      startTime: readingStartTime,
      wordList: WordList([sentenceSegment]),
    );
    readingMap.map[segmentRange] = Reading(timeline: timing);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence removeReading(PhrasePosition phrase) {
    readingMap.map.remove(phrase);
    return Sentence(vocalistID: vocalistID, timeline: timeline, readingMap: readingMap);
  }

  Sentence manipulateSnippet(SeekPosition seekPosition, SentenceEdge snippetEdge, bool holdLength) {
    Timeline newTiming = timeline.copyWith();
    newTiming = newTiming.manipulateTiming(seekPosition, snippetEdge, holdLength);
    return Sentence(vocalistID: vocalistID, timeline: newTiming, readingMap: readingMap);
  }

  Tuple2<Sentence, Sentence> dividSnippet(InsertionPosition charPosition, SeekPosition seekPosition) {
    String formerString = sentence.substring(0, charPosition.position);
    String latterString = sentence.substring(charPosition.position);
    Sentence snippet1 = Sentence.empty;
    Sentence snippet2 = Sentence.empty;

    if (formerString.isNotEmpty) {
      Timeline newTiming = timeline.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      snippet1 = Sentence(
        vocalistID: vocalistID,
        timeline: newTiming,
        readingMap: readingMap,
      );
    }

    if (latterString.isNotEmpty) {
      Timeline newTiming = timeline.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      snippet2 = Sentence(
        vocalistID: vocalistID,
        timeline: newTiming,
        readingMap: readingMap,
      );
    }

    return Tuple2(snippet1, snippet2);
  }

  ReadingMap carryUpReadingPhrases(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timeline.getInsertionPositionInfo(insertionPosition)!;
    Map<PhrasePosition, Reading> updatedReadings = {};

    readingMap.map.forEach((PhrasePosition key, Reading value) {
      PhrasePosition newKey = key.copyWith();

      switch (info) {
        case SentenceSegmentInsertionPositionInfo():
          WordIndex index = info.sentenceSegmentIndex;
          if (index < key.startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index <= key.endIndex) {
            newKey.endIndex++;
          }
          break;

        case TimingPointInsertionPositionInfo():
          TimingIndex index = info.timingPointIndex;
          TimingIndex startIndex = timeline.leftTimingIndex(key.startIndex);
          TimingIndex endIndex = timeline.rightTimingIndex(key.endIndex);
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

      updatedReadings[newKey] = value;
    });

    return ReadingMap(updatedReadings);
  }

  ReadingMap carryDownReadingPhrase(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timeline.getInsertionPositionInfo(insertionPosition)!;
    Map<PhrasePosition, Reading> updatedReadings = {};
    int index = -1;
    if (info is SentenceSegmentInsertionPositionInfo) {
      index = info.sentenceSegmentIndex.index;
    } else if (info is TimingPointInsertionPositionInfo) {
      index = info.timingPointIndex.index;
    } else {
      assert(false, "An unexpected state was occurred for the insertion position");
    }

    readingMap.map.forEach((PhrasePosition key, Reading value) {
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
      updatedReadings[newKey] = value;
    });

    return ReadingMap(updatedReadings);
  }

  List<Tuple2<PhrasePosition, Reading?>> getReadingExistenceRangeList() {
    if (readingMap.isEmpty) {
      WordIndex startIndex = WordIndex(0);
      WordIndex endIndex = WordIndex(sentenceSegments.length - 1);
      return [
        Tuple2(
          PhrasePosition(startIndex, endIndex),
          null,
        ),
      ];
    }

    List<Tuple2<PhrasePosition, Reading?>> rangeList = [];
    int previousEnd = -1;

    for (MapEntry<PhrasePosition, Reading> entry in readingMap.entries) {
      PhrasePosition phrase = entry.key;
      Reading reading = entry.value;

      if (previousEnd + 1 <= phrase.startIndex.index - 1) {
        WordIndex startIndex = WordIndex(previousEnd + 1);
        WordIndex endIndex = WordIndex(phrase.startIndex.index - 1);
        rangeList.add(
          Tuple2(
            PhrasePosition(startIndex, endIndex),
            null,
          ),
        );
      }
      rangeList.add(
        Tuple2(
          phrase,
          reading,
        ),
      );

      previousEnd = phrase.endIndex.index;
    }

    if (previousEnd + 1 <= sentenceSegments.length - 1) {
      WordIndex startIndex = WordIndex(previousEnd + 1);
      WordIndex endIndex = WordIndex(sentenceSegments.length - 1);
      rangeList.add(
        Tuple2(
          PhrasePosition(startIndex, endIndex),
          null,
        ),
      );
    }

    return rangeList;
  }

  Sentence copyWith({
    VocalistID? vocalistID,
    Timeline? timing,
    ReadingMap? readingMap,
  }) {
    return Sentence(
      vocalistID: vocalistID ?? this.vocalistID,
      timeline: timing ?? this.timeline,
      readingMap: readingMap ?? this.readingMap,
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
    return vocalistID == other.vocalistID && timeline == other.timeline && readingMap == other.readingMap;
  }

  @override
  int get hashCode => vocalistID.hashCode ^ timeline.hashCode ^ readingMap.hashCode;
}
