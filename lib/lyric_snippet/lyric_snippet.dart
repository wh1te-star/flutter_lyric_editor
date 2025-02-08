import 'package:flutter/foundation.dart';
import 'package:lyric_editor/lyric_snippet/annotation.dart';
import 'package:lyric_editor/lyric_snippet/position_type_info.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing_object.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';

class LyricSnippet with TimingObject {
  VocalistID vocalistID;
  Map<SegmentRange, Annotation> annotations;

  LyricSnippet({
    required this.vocalistID,
    required startTimestamp,
    required List<SentenceSegment> sentenceSegments,
    required this.annotations,
  }) {
    this.startTimestamp = startTimestamp;
    this.sentenceSegments = sentenceSegments;
    updateTimingPoints();
  }

  static LyricSnippet get emptySnippet {
    return LyricSnippet(
      vocalistID: VocalistID(0),
      startTimestamp: 0,
      sentenceSegments: [],
      annotations: {},
    );
  }

  MapEntry<SegmentRange, Annotation> getAnnotationWords(int index) {
    return annotations.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(SegmentRange(-1, -1), Annotation.emptySnippet),
    );
  }

  int? getAnnotationIndexFromSeekPosition(int seekPosition) {
    for (MapEntry<SegmentRange, Annotation> entry in annotations.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      int startSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotation.timingPoints.first.seekPosition;
      int endSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotation.timingPoints.last.seekPosition;
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range.startIndex;
      }
    }
    return null;
  }

  @override
  void addTimingPoint(int charPosition, int seekPosition) {
    carryUpAnnotationSegments(charPosition);
    super.addTimingPoint(charPosition, seekPosition);
  }

  @override
  void deleteTimingPoint(int charPosition, Option option) {
    carryDownAnnotationSegments(charPosition);
    super.deleteTimingPoint(charPosition, option);
  }

  Map<SegmentRange, Annotation> copyAnnotationMap() {
    return annotations.map((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();
      Annotation newValue = value.copyWith();
      return MapEntry(newKey, newValue);
    });
  }

  void carryUpAnnotationSegments(int charPosition) {
    PositionTypeInfo info = getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int index = info.index;

    annotations.forEach((SegmentRange key, Annotation value) {
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

    annotations = updatedAnnotations;
  }

  void carryDownAnnotationSegments(int charPosition) {
    PositionTypeInfo info = getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int timingPointIndex = info.index;

    annotations.forEach((SegmentRange key, Annotation value) {
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

    annotations = updatedAnnotations;
  }

  void addAnnotation(String annotationString, int startIndex, int endIndex) {
    int duration = sentenceSegments.sublist(startIndex, endIndex + 1).fold(0, (sum, segment) => sum + segment.duration);
    TimingPoint justBeforeTimingPoint = timingPoints[startIndex];
    SegmentRange annotationKey = SegmentRange(startIndex, endIndex);
    annotations[annotationKey] = Annotation(startTimestamp: startTimestamp + justBeforeTimingPoint.seekPosition, sentenceSegments: [
      SentenceSegment(
        annotationString,
        duration,
      ),
    ]);
  }

  void deleteAnnotation(SegmentRange range) {
    annotations.remove(range);
  }

  LyricSnippet copyWith({
    VocalistID? vocalistID,
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
    Map<SegmentRange, Annotation>? annotations,
  }) {
    return LyricSnippet(
      vocalistID: vocalistID ?? this.vocalistID,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments ?? this.sentenceSegments,
      annotations: annotations ?? this.annotations,
    );
  }

  @override
  bool operator ==(Object other) {
    if(identical(this, other)){
      return true;
    }
    if(other is! LyricSnippet){
      return false;
    }
    if(runtimeType != other.runtimeType){
      return false;
    }
    return vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(sentenceSegments, other.sentenceSegments);
  }

  @override
  int get hashCode => Object.hash(vocalistID, startTimestamp, Object.hashAll(sentenceSegments));
}
