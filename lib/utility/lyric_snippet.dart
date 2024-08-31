import 'package:flutter/foundation.dart';
import 'package:lyric_editor/utility/id_generator.dart';

class LyricSnippet {
  VocalistID vocalistID;
  String sentence;
  int startTimestamp;
  List<SentenceSegment> sentenceSegments;
  late List<SentenceSegment> accumulatedSentenceSegments;

  LyricSnippet({
    required this.vocalistID,
    required this.sentence,
    required this.startTimestamp,
    required this.sentenceSegments,
  });

  int get endTimestamp {
    return startTimestamp + sentenceSegments.fold(0, (sum, current) => sum + current.wordDuration);
  }

  int charPosition(int index) {
    if (index < 0 || index >= sentenceSegments.length) {
      throw RangeError('Index ${index} is out of bounds for sentenceSegments with length ${sentenceSegments.length}');
    }
    return sentenceSegments.take(index + 1).fold(0, (sum, current) => sum + current.wordLength);
  }

  static LyricSnippet get emptySnippet {
    return LyricSnippet(
      vocalistID: VocalistID(0),
      sentence: "",
      startTimestamp: 0,
      sentenceSegments: [],
    );
  }

  int seekPosition(int index) {
    if (index < 0 || index >= sentenceSegments.length) {
      throw RangeError('Index ${index} is out of bounds for sentenceSegments with length ${sentenceSegments.length}');
    }
    return sentenceSegments.take(index + 1).fold(0, (sum, current) => sum + current.wordDuration);
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
      sentenceSegments: sentenceSegments != null ? sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList() : this.sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList(),
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(sentenceSegments, other.sentenceSegments);

  @override
  int get hashCode => vocalistID.hashCode ^ sentence.hashCode ^ startTimestamp.hashCode ^ sentenceSegments.hashCode;
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
