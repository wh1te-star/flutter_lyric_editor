import 'package:flutter/foundation.dart';

class LyricSnippetID {
  int id;
  LyricSnippetID(this.id);

  @override
  bool operator ==(Object other) {
    if (other is LyricSnippetID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LyricSnippetID($id)';
}

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
      sentenceSegments: sentenceSegments != null ? List<SentenceSegment>.from(sentenceSegments) : List<SentenceSegment>.from(this.sentenceSegments),
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(sentenceSegments, other.sentenceSegments);

  @override
  int get hashCode => vocalistID.hashCode ^ sentence.hashCode ^ startTimestamp.hashCode ^ sentenceSegments.hashCode;
}

class VocalistID {
  int id;
  VocalistID(this.id);

  @override
  bool operator ==(Object other) {
    if (other is VocalistID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VocalistID($id)';
}

class Vocalist {
  String name;
  int color;
  Vocalist(this.name, this.color);

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
