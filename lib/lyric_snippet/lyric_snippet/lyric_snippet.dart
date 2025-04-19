import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class LyricSnippet {
  final VocalistID vocalistID;
  final Timing timing;
  final AnnotationMap annotationMap;

  LyricSnippet({
    required this.vocalistID,
    required this.timing,
    required this.annotationMap,
  });

  static LyricSnippet get empty => LyricSnippet(
        vocalistID: VocalistID(0),
        timing: Timing.empty,
        annotationMap: AnnotationMap.empty,
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
  SentenceSegmentList getSentenceSegmentList(SegmentRange segmentRange) => timing.getSentenceSegmentList(segmentRange);

  MapEntry<SegmentRange, Annotation> getAnnotationWords(SentenceSegmentIndex index) {
    return annotationMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(SegmentRange.empty, Annotation.empty),
    );
  }

  SegmentRange getAnnotationRangeFromSeekPosition(SeekPosition seekPosition) {
    for (MapEntry<SegmentRange, Annotation> entry in annotationMap.map.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      SeekPosition startTimestamp = timing.startTimestamp;
      List<TimingPoint> timingPoints = timing.timingPointList.list;
      List<TimingPoint> annotationTimingPoints = annotation.timing.timingPointList.list;
      SeekPosition annotationStartSeekPosition = SeekPosition(startTimestamp.position + timingPoints[range.startIndex.index].seekPosition.position);
      SeekPosition startSeekPosition = SeekPosition(annotationStartSeekPosition.position + annotationTimingPoints.first.seekPosition.position);
      SeekPosition endSeekPosition = SeekPosition(annotationStartSeekPosition.position + annotationTimingPoints.last.seekPosition.position);
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range;
      }
    }
    return SegmentRange.empty;
  }

  LyricSnippet editSentence(String newSentence) {
    Timing copiedTiming = timing.copyWith();
    copiedTiming = copiedTiming.editSentence(newSentence);
    return LyricSnippet(vocalistID: vocalistID, timing: copiedTiming, annotationMap: annotationMap);
  }

  LyricSnippet addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    AnnotationMap annotationMap = carryUpAnnotationSegments(charPosition);
    Timing timing = this.timing.addTimingPoint(charPosition, seekPosition);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeTimingPoint(InsertionPosition charPosition, Option option) {
    AnnotationMap annotationMap = carryDownAnnotationSegments(charPosition);
    Timing timing = this.timing.deleteTimingPoint(charPosition, option);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet addAnnotationTimingPoint(SegmentRange segmentRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    Timing timing = annotationMap[segmentRange]!.timing.addTimingPoint(charPosition, seekPosition);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeAnnotationTimingPoint(SegmentRange segmentRange, InsertionPosition charPosition, Option option) {
    Timing timing = annotationMap[segmentRange]!.timing.deleteTimingPoint(charPosition, option);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet addAnnotation(SegmentRange segmentRange, String annotationString) {
    AnnotationMap annotationMap = this.annotationMap;
    SeekPosition annotationStartTimestamp = SeekPosition(startTimestamp.position + timingPoints[segmentRange.startIndex.index].seekPosition.position);
    SeekPosition annotationEndTimestamp = SeekPosition(startTimestamp.position + timingPoints[segmentRange.endIndex.index + 1].seekPosition.position);
    Duration annotationDuration = Duration(milliseconds: annotationEndTimestamp.position - annotationStartTimestamp.position);
    SentenceSegment sentenceSegment = SentenceSegment(annotationString, annotationDuration);
    Timing timing = Timing(
      startTimestamp: annotationStartTimestamp,
      sentenceSegmentList: SentenceSegmentList([sentenceSegment]),
    );
    annotationMap.map[segmentRange] = Annotation(timing: timing);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeAnnotation(SegmentRange range) {
    AnnotationMap annotationMap = this.annotationMap;
    annotationMap.map.remove(range);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet manipulateSnippet(SeekPosition seekPosition, SnippetEdge snippetEdge, bool holdLength) {
    Timing newTiming = timing.copyWith();
    newTiming = newTiming.manipulateTiming(seekPosition, snippetEdge, holdLength);
    return LyricSnippet(vocalistID: vocalistID, timing: newTiming, annotationMap: annotationMap);
  }

  Tuple2<LyricSnippet, LyricSnippet> dividSnippet(InsertionPosition charPosition, SeekPosition seekPosition) {
    String formerString = sentence.substring(0, charPosition.position);
    String latterString = sentence.substring(charPosition.position);
    LyricSnippet snippet1 = LyricSnippet.empty;
    LyricSnippet snippet2 = LyricSnippet.empty;

    if (formerString.isNotEmpty) {
      Timing newTiming = timing.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      snippet1 = LyricSnippet(
        vocalistID: vocalistID,
        timing: newTiming,
        annotationMap: annotationMap,
      );
    }

    if (latterString.isNotEmpty) {
      Timing newTiming = timing.copyWith();
      newTiming = newTiming.addTimingPoint(charPosition, seekPosition);
      snippet2 = LyricSnippet(
        vocalistID: vocalistID,
        timing: newTiming,
        annotationMap: annotationMap,
      );
    }

    return Tuple2(snippet1, snippet2);
  }

  AnnotationMap carryUpAnnotationSegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timing.getInsertionPositionInfo(insertionPosition)!;
    Map<SegmentRange, Annotation> updatedAnnotations = {};

    annotationMap.map.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();

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

      updatedAnnotations[newKey] = value;
    });

    return AnnotationMap(updatedAnnotations);
  }

  AnnotationMap carryDownAnnotationSegments(InsertionPosition insertionPosition) {
    InsertionPositionInfo info = timing.getInsertionPositionInfo(insertionPosition)!;
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int index = -1;
    if (info is SentenceSegmentInsertionPositionInfo) {
      index = info.sentenceSegmentIndex.index;
    } else if (info is TimingPointInsertionPositionInfo) {
      index = info.timingPointIndex.index;
    } else {
      assert(false, "An unexpected state was occurred for the insertion position");
    }

    annotationMap.map.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();
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

    return AnnotationMap(updatedAnnotations);
  }

  List<Tuple2<SegmentRange, Annotation?>> getAnnotationExistenceRangeList() {
    if (annotationMap.isEmpty) {
      SentenceSegmentIndex startIndex = SentenceSegmentIndex(0);
      SentenceSegmentIndex endIndex = SentenceSegmentIndex(sentenceSegments.length - 1);
      return [
        Tuple2(
          SegmentRange(startIndex, endIndex),
          null,
        ),
      ];
    }

    List<Tuple2<SegmentRange, Annotation?>> rangeList = [];
    int previousEnd = -1;

    for (MapEntry<SegmentRange, Annotation> entry in annotationMap.entries) {
      SegmentRange segmentRange = entry.key;
      Annotation annotation = entry.value;

      if (previousEnd + 1 <= segmentRange.startIndex.index - 1) {
        SentenceSegmentIndex startIndex = SentenceSegmentIndex(previousEnd + 1);
        SentenceSegmentIndex endIndex = SentenceSegmentIndex(segmentRange.startIndex.index - 1);
        rangeList.add(
          Tuple2(
            SegmentRange(startIndex, endIndex),
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
      SentenceSegmentIndex startIndex = SentenceSegmentIndex(previousEnd + 1);
      SentenceSegmentIndex endIndex = SentenceSegmentIndex(sentenceSegments.length - 1);
      rangeList.add(
        Tuple2(
          SegmentRange(startIndex, endIndex),
          null,
        ),
      );
    }

    return rangeList;
  }

  LyricSnippet copyWith({
    VocalistID? vocalistID,
    Timing? timing,
    AnnotationMap? annotationMap,
  }) {
    return LyricSnippet(
      vocalistID: vocalistID ?? this.vocalistID,
      timing: timing ?? this.timing,
      annotationMap: annotationMap ?? this.annotationMap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LyricSnippet) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return vocalistID == other.vocalistID && timing == other.timing && annotationMap == other.annotationMap;
  }

  @override
  int get hashCode => vocalistID.hashCode ^ timing.hashCode ^ annotationMap.hashCode;
}
