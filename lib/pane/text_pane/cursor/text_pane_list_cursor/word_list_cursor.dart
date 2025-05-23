import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class WordListCursor extends TextPaneListCursor {
  late WordCursor wordCursor;

  WordListCursor({
    required SentenceMap sentenceMap,
    required SentenceID sentenceID,
    required SeekPosition seekPosition,
    required PhrasePosition phrasePosition,
    required bool isExpandMode,
  }) : super(sentenceMap, sentenceID, seekPosition) {
    assert(isIDContained(), "The passed sentenceID does not point to a sentence in sentenceMap.");

    wordCursor = WordCursor(
      sentence: sentenceMap[sentenceID]!,
      seekPosition: seekPosition,
      phrasePosition: phrasePosition,
      isExpandMode: isExpandMode,
    );
    textPaneCursor = wordCursor;
  }

  bool isIDContained() {
    if (sentenceMap.isEmpty) {
      return true;
    }
    Sentence? sentence = sentenceMap[sentenceID];
    if (sentence == null) {
      return false;
    }
    return true;
  }

  WordListCursor._privateConstructor(
    super.sentenceMap,
    super.sentenceID,
    super.seekPosition,
  );
  static final WordListCursor _empty = WordListCursor._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    SeekPosition.empty,
  );
  static WordListCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  WordListCursor defaultCursor(SentenceID sentenceID) {
    WordCursor defaultCursor = wordCursor.defaultCursor();
    return WordListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrasePosition: defaultCursor.phrasePosition,
      isExpandMode: defaultCursor.isExpandMode,
    );
  }

  @override
  TextPaneListCursor moveUpCursor() {
    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });
    if (index <= 0) {
      return this;
    }

    SentenceID nextSentenceID = sentenceMap.keys.toList()[index - 1];
    return defaultCursor(nextSentenceID);
  }

  @override
  TextPaneListCursor moveDownCursor() {
    int index = sentenceMap.keys.toList().indexWhere((SentenceID id) {
      return id == sentenceID;
    });
    if (index + 1 >= sentenceMap.length) {
      return this;
    }

    SentenceID nextLyricSentenceID = sentenceMap.keys.toList()[index + 1];
    return defaultCursor(nextLyricSentenceID);
  }

  @override
  TextPaneListCursor moveLeftCursor() {
    WordCursor nextCursor = wordCursor.moveLeftCursor() as WordCursor;
    return WordListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrasePosition: nextCursor.phrasePosition,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  @override
  TextPaneListCursor moveRightCursor() {
    WordCursor nextCursor = wordCursor.moveRightCursor() as WordCursor;
    return WordListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrasePosition: nextCursor.phrasePosition,
      isExpandMode: nextCursor.isExpandMode,
    );
  }

  TextPaneListCursor exitWordMode() {
    return BaseListCursor.defaultCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
    );
  }

  TextPaneListCursor switchToExpandMode() {
    WordCursor nextCursor = wordCursor.switchToExpandMode() as WordCursor;
    return copyWith(phrasePosition: nextCursor.phrasePosition, isExpandMode: nextCursor.isExpandMode);
  }

  @override
  TextPaneListCursor updateCursor(
    SentenceMap sentenceMap,
    SentenceID sentenceID,
    SeekPosition seekPosition,
  ) {
    return WordListCursor(
      sentenceMap: sentenceMap,
      sentenceID: sentenceID,
      seekPosition: seekPosition,
      phrasePosition: wordCursor.phrasePosition,
      isExpandMode: wordCursor.isExpandMode,
    );
  }

  @override
  WordListCursor copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    SeekPosition? seekPosition,
    PhrasePosition? phrasePosition,
    bool? isExpandMode,
  }) {
    return WordListCursor(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      seekPosition: seekPosition ?? this.seekPosition,
      phrasePosition: phrasePosition ?? wordCursor.phrasePosition,
      isExpandMode: isExpandMode ?? wordCursor.isExpandMode,
    );
  }

  @override
  String toString() {
    return 'WordCursor(ID: ${sentenceID.id}, segmentIndex: $wordCursor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final WordListCursor otherSentenceSegments = other as WordListCursor;
    if (sentenceMap != otherSentenceSegments.sentenceMap) return false;
    if (sentenceID != otherSentenceSegments.sentenceID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (wordCursor != otherSentenceSegments.wordCursor) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ seekPosition.hashCode ^ wordCursor.hashCode;
}
