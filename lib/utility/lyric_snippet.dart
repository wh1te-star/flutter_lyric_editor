import 'package:flutter/foundation.dart';
import 'package:lyric_editor/utility/id_generator.dart';

class LyricSnippet {
  VocalistID vocalistID;
  String sentence;
  int startTimestamp;
  final List<SentenceSegment> _sentenceSegments;

  LyricSnippet({
    required this.vocalistID,
    required this.sentence,
    required this.startTimestamp,
    required List<SentenceSegment> sentenceSegments,
  }) : _sentenceSegments = sentenceSegments {
    updateTimingPoints();
  }

  List<TimingPoint> _timingPoints = [];

  List<SentenceSegment> get sentenceSegments => _sentenceSegments;
  set sentenceSegments(List<SentenceSegment> segments) {
    _sentenceSegments.clear();
    _sentenceSegments.addAll(segments);
    updateTimingPoints();
  }

  List<TimingPoint> get timingPoints => _timingPoints;

  int get endTimestamp {
    return startTimestamp + _timingPoints.last.seekPosition;
  }

  void updateTimingPoints() {
    List<TimingPoint> newTimingPoints = [];
    int charPosition = 0;
    int seekPosition = 0;
    for (var segment in sentenceSegments) {
      newTimingPoints.add(TimingPoint(charPosition, seekPosition));
      charPosition += segment.wordLength;
      seekPosition += segment.wordDuration;
    }
    newTimingPoints.add(TimingPoint(charPosition, seekPosition));

    _timingPoints = newTimingPoints;
  }

  int charPosition(int index) {
    if (index < 0 || index >= _sentenceSegments.length) {
      throw RangeError('Index ${index} is out of bounds for sentenceSegments with length ${_sentenceSegments.length}');
    }
    return _sentenceSegments.take(index + 1).fold(0, (sum, current) => sum + current.wordLength);
  }

  int seekPosition(int index) {
    if (index < 0 || index >= _sentenceSegments.length) {
      throw RangeError('Index ${index} is out of bounds for sentenceSegments with length ${_sentenceSegments.length}');
    }
    return _sentenceSegments.take(index + 1).fold(0, (sum, current) => sum + current.wordDuration);
  }

  static LyricSnippet get emptySnippet {
    return LyricSnippet(
      vocalistID: VocalistID(0),
      sentence: "",
      startTimestamp: 0,
      sentenceSegments: [],
    );
  }

  LyricSnippet copyWith({
    VocalistID? vocalistID,
    String? sentence,
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
  }) {
    return LyricSnippet(
      vocalistID: vocalistID ?? this.vocalistID,
      sentence: sentence ?? this.sentence,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments != null ? sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList() : this._sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList(),
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(_sentenceSegments, other._sentenceSegments);

  @override
  int get hashCode => vocalistID.hashCode ^ sentence.hashCode ^ startTimestamp.hashCode ^ _sentenceSegments.hashCode;
}

class Vocalist {
  String name;
  int color;
  Vocalist({
    required this.name,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Vocalist otherVocalist = other as Vocalist;
    return name == otherVocalist.name && color == otherVocalist.color;
  }

  @override
  int get hashCode => name.hashCode ^ color.hashCode;
}

class VocalistCombination {
  List<String> vocalistNames;

  VocalistCombination(this.vocalistNames);

  @override
  bool operator ==(Object other) => identical(this, other) || other is VocalistCombination && runtimeType == other.runtimeType && listEquals(vocalistNames..sort(), other.vocalistNames..sort());

  @override
  int get hashCode => vocalistNames.fold(0, (prev, element) => 31 * prev + element.hashCode);
}

class SentenceSegment {
  int wordLength;
  int wordDuration;

  SentenceSegment(this.wordLength, this.wordDuration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSegment otherSentenceSegments = other as SentenceSegment;
    return wordLength == otherSentenceSegments.wordLength && wordDuration == otherSentenceSegments.wordDuration;
  }

  @override
  int get hashCode => wordLength.hashCode ^ wordDuration.hashCode;

  @override
  String toString() {
    return 'SentenceSegment(wordLength: $wordLength, wordDuration: $wordDuration)';
  }
}

class TimingPoint {
  int charPosition;
  int seekPosition;

  TimingPoint(this.charPosition, this.seekPosition);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherSentenceSegments = other as TimingPoint;
    return charPosition == otherSentenceSegments.charPosition && seekPosition == otherSentenceSegments.seekPosition;
  }

  @override
  int get hashCode => charPosition.hashCode ^ seekPosition.hashCode;

  @override
  String toString() {
    return 'TimingPoint(charPosition: $charPosition, seekPosition: $seekPosition)';
  }
}
