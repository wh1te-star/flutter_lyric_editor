import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
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
  List<TimingPoint> get timingPoints => timeline.timingList.list;
  int get charLength => timeline.charCount;
  int get segmentLength => timeline.segmentCount;
  WordIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timeline.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timeline.getInsertionPositionInfo(insertionPosition);
  double getSegmentProgress(SeekPosition seekPosition) => timeline.getSegmentProgress(seekPosition);
  WordList getSentenceSegmentList(Phrase segmentRange) => timeline.getSentenceSegmentList(segmentRange);
  TimingIndex leftTimingPointIndex(WordIndex segmentIndex) => timeline.leftTimingIndex(segmentIndex);
  TimingIndex rightTimingPointIndex(WordIndex segmentIndex) => timeline.rightTimingIndex(segmentIndex);
  TimingPoint leftTimingPoint(WordIndex segmentIndex) => timeline.leftTiming(segmentIndex);
  TimingPoint rightTimingPoint(WordIndex segmentIndex) => timeline.rightTiming(segmentIndex);

  MapEntry<Phrase, Reading> getAnnotationWords(WordIndex index) {
    return readingMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(Phrase.empty, Reading.empty),
    );
  }

  Phrase getAnnotationRangeFromSeekPosition(SeekPosition seekPosition) {
    for (MapEntry<Phrase, Reading> entry in readingMap.map.entries) {
      Phrase range = entry.key;
      Reading annotation = entry.value;
      SeekPosition startTimestamp = timeline.startTime;
      List<TimingPoint> timingPoints = timeline.timingList.list;
      List<TimingPoint> annotationTimingPoints = annotation.timeline.timingList.list;
      SeekPosition annotationStartSeekPosition = SeekPosition(startTimestamp.position + timingPoints[range.startIndex.index].seekPosition.position);
      SeekPosition startSeekPosition = SeekPosition(annotationStartSeekPosition.position + annotationTimingPoints.first.seekPosition.position);
      SeekPosition endSeekPosition = SeekPosition(annotationStartSeekPosition.position + annotationTimingPoints.last.seekPosition.position);
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range;
      }
    }
    return Phrase.empty;
  }

  Sentence editSentence(String newSentence) {
    Timeline copiedTiming = timeline.copyWith();
    copiedTiming = copiedTiming.editSentence(newSentence);
    return Sentence(vocalistID: vocalistID, timeline: copiedTiming, readingMap: readingMap);
  }

  Sentence addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    ReadingMap annotationMap = carryUpAnnotationSegments(charPosition);
    Timeline timing = this.timeline.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: annotationMap);
  }

  Sentence removeTimingPoint(InsertionPosition charPosition, Option option) {
    ReadingMap annotationMap = carryDownAnnotationSegments(charPosition);
    Timeline timing = this.timeline.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: annotationMap);
  }

  Sentence addAnnotationTimingPoint(Phrase segmentRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    Timeline timing = readingMap[segmentRange]!.timeline.addTimingPoint(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence removeAnnotationTimingPoint(Phrase segmentRange, InsertionPosition charPosition, Option option) {
    Timeline timing = readingMap[segmentRange]!.timeline.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: readingMap);
  }

  Sentence addAnnotation(Phrase segmentRange, String annotationString) {
    ReadingMap annotationMap = this.readingMap;
    SeekPosition annotationStartTimestamp = SeekPosition(startTimestamp.position + timingPoints[segmentRange.startIndex.index].seekPosition.position);
    SeekPosition annotationEndTimestamp = SeekPosition(startTimestamp.position + timingPoints[segmentRange.endIndex.index + 1].seekPosition.position);
    Duration annotationDuration = Duration(milliseconds: annotationEndTimestamp.position - annotationStartTimestamp.position);
    Word sentenceSegment = Word(annotationString, annotationDuration);
    Timeline timing = Timeline(
      startTime: annotationStartTimestamp,
      wordList: WordList([sentenceSegment]),
    );
    annotationMap.map[segmentRange] = Reading(timeline: timing);
    return Sentence(vocalistID: vocalistID, timeline: timing, readingMap: annotationMap);
  }

  Sentence removeAnnotation(Phrase range) {
    ReadingMap annotationMap = this.readingMap;
    annotationMap.map.remove(range);
    return Sentence(vocalistID: vocalistID, timeline: timeline, readingMap: annotationMap);
  }

  Sentence manipulateSnippet(SeekPosition seekPosition, SnippetEdge snippetEdge, bool holdLength) {
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

  ReadingMap carryUpAnnotationSegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timeline.getInsertionPositionInfo(insertionPosition)!;
    Map<Phrase, Reading> updatedAnnotations = {};

    readingMap.map.forEach((Phrase key, Reading value) {
      Phrase newKey = key.copyWith();

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

      updatedAnnotations[newKey] = value;
    });

    return ReadingMap(updatedAnnotations);
  }

  ReadingMap carryDownAnnotationSegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timeline.getInsertionPositionInfo(insertionPosition)!;
    Map<Phrase, Reading> updatedAnnotations = {};
    int index = -1;
    if (info is SentenceSegmentInsertionPositionInfo) {
      index = info.sentenceSegmentIndex.index;
    } else if (info is TimingPointInsertionPositionInfo) {
      index = info.timingPointIndex.index;
    } else {
      assert(false, "An unexpected state was occurred for the insertion position");
    }

    readingMap.map.forEach((Phrase key, Reading value) {
      Phrase newKey = key.copyWith();
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
      updatedAnnotations[newKey] = value;
    });

    return ReadingMap(updatedAnnotations);
  }

  List<Tuple2<Phrase, Reading?>> getAnnotationExistenceRangeList() {
    if (readingMap.isEmpty) {
      WordIndex startIndex = WordIndex(0);
      WordIndex endIndex = WordIndex(sentenceSegments.length - 1);
      return [
        Tuple2(
          Phrase(startIndex, endIndex),
          null,
        ),
      ];
    }

    List<Tuple2<Phrase, Reading?>> rangeList = [];
    int previousEnd = -1;

    for (MapEntry<Phrase, Reading> entry in readingMap.entries) {
      Phrase segmentRange = entry.key;
      Reading annotation = entry.value;

      if (previousEnd + 1 <= segmentRange.startIndex.index - 1) {
        WordIndex startIndex = WordIndex(previousEnd + 1);
        WordIndex endIndex = WordIndex(segmentRange.startIndex.index - 1);
        rangeList.add(
          Tuple2(
            Phrase(startIndex, endIndex),
            null,
          ),
        );
      }
      rangeList.add(
        Tuple2(
          segmentRange,
          annotation,
        ),
      );

      previousEnd = segmentRange.endIndex.index;
    }

    if (previousEnd + 1 <= sentenceSegments.length - 1) {
      WordIndex startIndex = WordIndex(previousEnd + 1);
      WordIndex endIndex = WordIndex(sentenceSegments.length - 1);
      rangeList.add(
        Tuple2(
          Phrase(startIndex, endIndex),
          null,
        ),
      );
    }

    return rangeList;
  }

  Sentence copyWith({
    VocalistID? vocalistID,
    Timeline? timing,
    ReadingMap? annotationMap,
  }) {
    return Sentence(
      vocalistID: vocalistID ?? this.vocalistID,
      timeline: timing ?? this.timeline,
      readingMap: annotationMap ?? this.readingMap,
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
