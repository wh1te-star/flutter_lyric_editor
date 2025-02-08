import 'package:flutter/foundation.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing_object.dart';

class Annotation with TimingObject {
  Annotation({
    required int startTimestamp,
    required List<SentenceSegment> sentenceSegments,
  }) {
    this.startTimestamp = startTimestamp;
    this.sentenceSegments = sentenceSegments;
    updateTimingPoints();
  }

  static Annotation get emptySnippet {
    return Annotation(
      startTimestamp: 0,
      sentenceSegments: [],
    );
  }

  Annotation copyWith({
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
  }) {
    return Annotation(
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments ?? this.sentenceSegments,
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
    return sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(sentenceSegments, other.sentenceSegments);
  }

  @override
  int get hashCode => Object.hash(startTimestamp, Object.hashAll(sentenceSegments));
}
