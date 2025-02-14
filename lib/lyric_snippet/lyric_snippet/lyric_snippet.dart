import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/position_type_info.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing_object.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
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
  bool get isEmpty => vocalistID.id == 0 && timing.startTimestamp == 0 && timing.isEmpty;

  String get sentence => timing.sentence;
  int get startTimestamp => timing.startTimestamp;
  int get endTimestamp => timing.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timing.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timing.timingPointList.list;

  MapEntry<SegmentRange, Annotation> getAnnotationWords(int index) {
    return annotationMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(SegmentRange(-1, -1), Annotation.empty),
    );
  }

  int? getAnnotationIndexFromSeekPosition(int seekPosition) {
    for (MapEntry<SegmentRange, Annotation> entry in annotationMap.map.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      int startTimestamp = timing.startTimestamp;
      List<TimingPoint> timingPoints = timing.timingPointList.list;
      List<TimingPoint> annotationTimingPoints = annotation.timing.timingPointList.list;
      int startSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotationTimingPoints.first.seekPosition;
      int endSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotationTimingPoints.last.seekPosition;
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range.startIndex;
      }
    }
    return null;
  }

  LyricSnippet editSentence(String newSentence) {
    Timing copiedTiming = timing.copyWith();
    copiedTiming = copiedTiming.editSentence(newSentence);
    return LyricSnippet(vocalistID: vocalistID, timing: copiedTiming, annotationMap: annotationMap);
  }

  LyricSnippet addTimingPoint(int charPosition, int seekPosition) {
    AnnotationMap annotationMap = carryUpAnnotationSegments(charPosition);
    Timing timing = this.timing.addTimingPoint(charPosition, seekPosition);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeTimingPoint(int charPosition, Option option) {
    AnnotationMap annotationMap = carryDownAnnotationSegments(charPosition);
    Timing timing = this.timing.deleteTimingPoint(charPosition, option);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet addAnnotationTimingPoint(SegmentRange segmentRange, int charPosition, int seekPosition) {
    Timing timing = annotationMap[segmentRange]!.timing.addTimingPoint(charPosition, seekPosition);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeAnnotationTimingPoint(SegmentRange segmentRange, int charPosition, Option option) {
    Timing timing = annotationMap[segmentRange]!.timing.deleteTimingPoint(charPosition, option);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet addAnnotation(SegmentRange segmentRange, String annotationString) {
    AnnotationMap annotationMap = this.annotationMap;
    Timing timing = this.timing;
    annotationMap.map[segmentRange] = Annotation(timing: timing);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet removeAnnotation(SegmentRange range) {
    AnnotationMap annotationMap = this.annotationMap;
    annotationMap.map.remove(range);
    return LyricSnippet(vocalistID: vocalistID, timing: timing, annotationMap: annotationMap);
  }

  LyricSnippet manipulateSnippet(int seekPosition, SnippetEdge snippetEdge, bool holdLength) {
    Timing newTiming = timing.copyWith();
    newTiming = newTiming.manipulateTiming(seekPosition, snippetEdge, holdLength);
    return LyricSnippet(vocalistID: vocalistID, timing: newTiming, annotationMap: annotationMap);
  }

  Tuple2<LyricSnippet, LyricSnippet> dividSnippet(int charPosition, int seekPosition) {
    String formerString = sentence.substring(0, charPosition);
    String latterString = sentence.substring(charPosition);
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

  AnnotationMap carryUpAnnotationSegments(int charPosition) {
    PositionTypeInfo info = timing.getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int index = info.index;

    annotationMap.map.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();

      switch (info.type) {
        case PositionType.sentenceSegment:
          if (index < key.startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index <= key.endIndex) {
            newKey.endIndex++;
          }
          break;
        case PositionType.timingPoint:
          int startIndex = key.startIndex;
          int endIndex = key.endIndex + 1;
          if (index <= startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index < endIndex) {
            newKey.endIndex++;
          }
          break;
      }
      updatedAnnotations[newKey] = value;
    });

    return AnnotationMap(updatedAnnotations);
  }

  AnnotationMap carryDownAnnotationSegments(int charPosition) {
    PositionTypeInfo info = timing.getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int timingPointIndex = info.index;

    annotationMap.map.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();
      int startIndex = key.startIndex;
      int endIndex = key.endIndex + 1;
      if (timingPointIndex == startIndex && timingPointIndex == endIndex + 1) {
        if (info.duplicate) {
          newKey.startIndex--;
          newKey.endIndex--;
        } else {
          return;
        }
      } else if (timingPointIndex < startIndex) {
        newKey.startIndex--;
        newKey.endIndex--;
      } else if (timingPointIndex < endIndex) {
        newKey.endIndex--;
      }
      updatedAnnotations[newKey] = value;
    });

    return AnnotationMap(updatedAnnotations);
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
