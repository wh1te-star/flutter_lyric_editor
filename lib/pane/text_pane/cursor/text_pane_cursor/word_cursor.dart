import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class WordCursor extends TextPaneCursor {
  PhrasePosition phrasePosition;
  bool isExpandMode = false;

  WordCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.phrasePosition,
    required this.isExpandMode,
  }) : super(sentence, seekPosition);

  WordCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.phrasePosition,
    this.isExpandMode,
  );
  static final WordCursor _empty = WordCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    PhrasePosition.empty,
    false,
  );
  static WordCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  WordCursor defaultCursor() {
    SentenceSegmentIndex segmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: PhrasePosition(segmentIndex, segmentIndex),
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    PhrasePosition nextPhrasePosition = phrasePosition.copyWith();

    if (!isExpandMode) {
      SentenceSegmentIndex currentIndex = phrasePosition.startIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < SentenceSegmentIndex(0)) {
        return this;
      }
      nextPhrasePosition.startIndex = nextIndex;

      nextPhrasePosition.endIndex = phrasePosition.endIndex - 1;
    } else {
      SentenceSegmentIndex currentIndex = phrasePosition.endIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < phrasePosition.startIndex) {
        return this;
      }
      nextPhrasePosition.startIndex = phrasePosition.startIndex;
      nextPhrasePosition.endIndex = nextIndex;
    }

    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: nextPhrasePosition,
      isExpandMode: isExpandMode,
    );
  }

  @override
  TextPaneCursor moveRightCursor() {
    PhrasePosition nextPhrasePosition = phrasePosition.copyWith();

    SentenceSegmentIndex currentIndex = phrasePosition.endIndex;
    SentenceSegmentIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= sentence.sentenceSegments.length) {
      return this;
    }

    nextPhrasePosition.endIndex = nextIndex;
    if (!isExpandMode) {
      nextPhrasePosition.startIndex = phrasePosition.startIndex + 1;
    }

    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: nextPhrasePosition,
      isExpandMode: isExpandMode,
    );
  }

  TextPaneCursor exitWordMode() {
    return BaseCursor.defaultCursor(
      sentence: sentence,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToExpandMode() {
    bool isExpandMode = !this.isExpandMode;
    return copyWith(isExpandMode: isExpandMode);
  }

  @override
  List<TextPaneCursor?> getPhrasePositionDividedCursors(Sentence sentence, List<PhrasePosition> phrasePositionList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(phrasePositionList.length, null);

    int startPhrasePositionIndex = phrasePositionList.indexWhere((PhrasePosition phrasePosition) {
      return phrasePosition.isInRange(cursor.phrasePosition.startIndex);
    });
    int endPhrasePositionIndex = phrasePositionList.indexWhere((PhrasePosition phrasePosition) {
      return phrasePosition.isInRange(cursor.phrasePosition.endIndex);
    });

    int shiftLength = 0;
    for (int index = 0; index <= endPhrasePositionIndex; index++) {
      SentenceSegmentIndex startIndex = phrasePositionList[index].startIndex - shiftLength;
      SentenceSegmentIndex endIndex = phrasePositionList[index].endIndex - shiftLength;
      if (index == startPhrasePositionIndex) {
        startIndex = cursor.phrasePosition.startIndex - shiftLength;
      }
      if (index == endPhrasePositionIndex) {
        endIndex = cursor.phrasePosition.endIndex - shiftLength;
      }

      if (startPhrasePositionIndex <= index && index <= endPhrasePositionIndex) {
        separatedCursors[index] = cursor.copyWith(
          phrasePosition: PhrasePosition(startIndex, endIndex),
        );
      }
      shiftLength += phrasePositionList[index].length;
    }

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    WordCursor cursor = copyWith();
    List<WordCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    WordCursor initialCursor = WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      phrasePosition: PhrasePosition(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
      isExpandMode: isExpandMode,
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SentenceSegmentIndex segmentIndex = SentenceSegmentIndex(index);
      if (cursor.phrasePosition.isInRange(segmentIndex)) {
        separatedCursors[index] = initialCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  WordCursor shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    if (phrasePosition.startIndex.index - 1 < 0 || phrasePosition.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    SentenceSegmentIndex startIndex = phrasePosition.startIndex - sentenceSegmentList.segmentLength;
    SentenceSegmentIndex endIndex = phrasePosition.endIndex - sentenceSegmentList.segmentLength;
    PhrasePosition newPhrasePosition = PhrasePosition(startIndex, endIndex);
    return copyWith(phrasePosition: newPhrasePosition);
  }

  @override
  WordCursor shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    if (phrasePosition.startIndex.index - 1 < 0 || phrasePosition.endIndex.index - 1 < 0) {
      return WordCursor.empty;
    }
    SentenceSegmentIndex startIndex = phrasePosition.startIndex - 1;
    SentenceSegmentIndex endIndex = phrasePosition.endIndex - 1;
    PhrasePosition newPhrasePosition = PhrasePosition(startIndex, endIndex);
    return copyWith(phrasePosition: newPhrasePosition);
  }

  WordCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    PhrasePosition? phrasePosition,
    bool? isExpandMode,
  }) {
    return WordCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      phrasePosition: phrasePosition ?? this.phrasePosition,
      isExpandMode: isExpandMode ?? this.isExpandMode,
    );
  }

  @override
  String toString() {
    return 'WordCursor(ID: $sentence, segmentIndex: $phrasePosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final WordCursor otherSentenceSegments = other as WordCursor;
    if (sentence != otherSentenceSegments.sentence) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (phrasePosition != otherSentenceSegments.phrasePosition) return false;
    if (isExpandMode != otherSentenceSegments.isExpandMode) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ phrasePosition.hashCode ^ isExpandMode.hashCode;
}
