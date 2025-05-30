import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/timing/timing_list.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/timing_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/relative_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class Sentence {
  final VocalistID vocalistID;
  final Timetable timetable;
  final RubyMap rubyMap;

  Sentence({
    required this.vocalistID,
    required this.timetable,
    required this.rubyMap,
  });

  static Sentence get empty => Sentence(
        vocalistID: VocalistID(0),
        timetable: Timetable.empty,
        rubyMap: RubyMap.empty,
      );
  bool get isEmpty => vocalistID.id == 0 && timetable.isEmpty && rubyMap.isEmpty;

  String get sentence => timetable.sentence;
  AbsoluteSeekPosition get startTimestamp => timetable.startTimestamp.absolute;
  AbsoluteSeekPosition get endTimestamp => timetable.endTimestamp.absolute;
  WordList get words => timetable.wordList;
  TimingList get timings => timetable.timingList;
  int get charCount => timetable.charCount;
  int get wordCount => timetable.wordCount;
  SeekPositionInfo getSeekPositionInfoBySeekPosition(AbsoluteSeekPosition seekPosition) => timetable.getSeekPositionInfoBySeekPosition(seekPosition);
  CaretPositionInfo getCaretPositionInfo(CaretPosition caretPosition) => timetable.getCaretPositionInfo(caretPosition);
  WordList getWordList(WordRange wordRange) => timetable.getWordList(wordRange);
  TimingIndex getLeftTimingIndex(WordIndex wordIndex) => timetable.getLeftTimingIndex(wordIndex);
  TimingIndex getRightTimingIndex(WordIndex wordIndex) => timetable.getRightTimingIndex(wordIndex);
  Timing getLeftTiming(WordIndex wordIndex) => timetable.getLeftTiming(wordIndex);
  Timing getRightTiming(WordIndex wordIndex) => timetable.getRightTiming(wordIndex);

  MapEntry<WordRange, Ruby> getRubyWords(WordIndex index) {
    return rubyMap.map.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(WordRange.empty, Ruby.empty),
    );
  }

  WordRange getRubysWordRangeFromSeekPosition(AbsoluteSeekPosition seekPosition) {
    for (MapEntry<WordRange, Ruby> entry in rubyMap.map.entries) {
      WordRange wordRange = entry.key;
      Ruby ruby = entry.value;

      AbsoluteSeekPosition startSeekPosition = ruby.startTimestamp.absolute;
      AbsoluteSeekPosition endSeekPosition = ruby.endTimestamp.absolute;
      if (startSeekPosition < seekPosition && seekPosition < endSeekPosition) {
        return wordRange;
      }
    }
    return WordRange.empty;
  }

  Sentence editSentence(String newSentence) {
    Timetable copiedTimetable = timetable.copyWith();
    copiedTimetable = copiedTimetable.editSentence(newSentence);
    return Sentence(vocalistID: vocalistID, timetable: copiedTimetable, rubyMap: rubyMap);
  }

  Sentence addTiming(CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    RubyMap rubyMap = carryUpRubyWords(charPosition);
    Timetable timetable = this.timetable.addTiming(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeTiming(CaretPosition charPosition, Option option) {
    RubyMap rubyMap = carryDownRubyWords(charPosition);
    Timetable timetable = this.timetable.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence addRubyTiming(WordRange wordRange, CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    Timetable timetable = rubyMap[wordRange]!.timetable.addTiming(charPosition, seekPosition);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeRubyTiming(WordRange wordRange, CaretPosition charPosition, Option option) {
    Timetable timetable = rubyMap[wordRange]!.timetable.deleteTiming(charPosition, option);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence addRuby(WordRange wordRange, String rubyString) {
    RelativeSeekPosition rubyStartTimestamp = getLeftTiming(wordRange.startIndex).seekPosition.absolute.toRelative(startTimestamp);
    RelativeSeekPosition rubyEndTimestamp = getRightTiming(wordRange.endIndex).seekPosition.absolute.toRelative(startTimestamp);
    Duration rubyDuration = rubyStartTimestamp.absolute.durationUntil(rubyEndTimestamp);
    Word word = Word(rubyString, rubyDuration);
    Timetable timetable = Timetable(
      startTimestamp: rubyStartTimestamp,
      wordList: WordList([word]),
    );
    rubyMap.map[wordRange] = Ruby(timetable: timetable);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence removeRuby(WordRange wordRange) {
    RubyMap rubyMap = this.rubyMap;
    rubyMap.map.remove(wordRange);
    return Sentence(vocalistID: vocalistID, timetable: timetable, rubyMap: rubyMap);
  }

  Sentence manipulateSentence(AbsoluteSeekPosition seekPosition, SentenceSide sentenceSide, bool holdLength) {
    Timetable newTimetable = timetable.copyWith();
    newTimetable = newTimetable.manipulateTimetable(seekPosition, sentenceSide, holdLength);
    return Sentence(vocalistID: vocalistID, timetable: newTimetable, rubyMap: rubyMap);
  }

  Tuple2<Sentence, Sentence> divideSentence(CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    String formerString = sentence.substring(0, charPosition.position);
    String latterString = sentence.substring(charPosition.position);
    Sentence sentence1 = Sentence.empty;
    Sentence sentence2 = Sentence.empty;

    if (formerString.isNotEmpty) {
      Timetable newTimetable = timetable.copyWith();
      newTimetable = newTimetable.addTiming(charPosition, seekPosition);
      sentence1 = Sentence(
        vocalistID: vocalistID,
        timetable: newTimetable,
        rubyMap: rubyMap,
      );
    }

    if (latterString.isNotEmpty) {
      Timetable newTimetable = timetable.copyWith();
      newTimetable = newTimetable.addTiming(charPosition, seekPosition);
      sentence2 = Sentence(
        vocalistID: vocalistID,
        timetable: newTimetable,
        rubyMap: rubyMap,
      );
    }

    return Tuple2(sentence1, sentence2);
  }

  RubyMap carryUpRubyWords(CaretPosition caretPosition) {
    CaretPositionInfo info = timetable.getCaretPositionInfo(caretPosition);
    assert(info is! InvalidCaretPositionInfo);

    Map<WordRange, Ruby> updatedRubys = {};

    rubyMap.map.forEach((WordRange key, Ruby value) {
      WordRange newKey = key.copyWith();

      switch (info) {
        case WordCaretPositionInfo():
          WordIndex index = info.wordIndex;
          if (index < key.startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index <= key.endIndex) {
            newKey.endIndex++;
          }
          break;

        case TimingCaretPositionInfo():
          TimingIndex index = info.timingIndex;
          TimingIndex startIndex = timetable.getLeftTimingIndex(key.startIndex);
          TimingIndex endIndex = timetable.getRightTimingIndex(key.endIndex);
          if (index <= startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index < endIndex) {
            newKey.endIndex++;
          }
          break;

        default:
          assert(false, "An unexpected state occurred for the caret position info");
      }

      updatedRubys[newKey] = value;
    });

    return RubyMap(updatedRubys);
  }

  RubyMap carryDownRubyWords(CaretPosition caretPosition) {
    CaretPositionInfo info = timetable.getCaretPositionInfo(caretPosition);
    assert(info is! InvalidCaretPositionInfo);

    Map<WordRange, Ruby> updatedRubys = {};
    int index = -1;
    if (info is WordCaretPositionInfo) {
      index = info.wordIndex.index;
    } else if (info is TimingCaretPositionInfo) {
      index = info.timingIndex.index;
    } else {
      assert(false, "An unexpected state was occurred for the caret position");
    }

    rubyMap.map.forEach((WordRange key, Ruby value) {
      WordRange newKey = key.copyWith();
      int startIndex = key.startIndex.index;
      int endIndex = key.endIndex.index + 1;
      if (index == startIndex && index == endIndex + 1) {
        if (info is TimingCaretPositionInfo && info.duplicate) {
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
      updatedRubys[newKey] = value;
    });

    return RubyMap(updatedRubys);
  }

  List<Tuple2<WordRange, Ruby?>> getRubysWordRangeList() {
    if (rubyMap.isEmpty) {
      WordIndex startIndex = WordIndex(0);
      WordIndex endIndex = WordIndex(words.length - 1);
      return [
        Tuple2(
          WordRange(startIndex, endIndex),
          null,
        ),
      ];
    }

    List<Tuple2<WordRange, Ruby?>> wordRangeList = [];
    int previousEnd = -1;

    for (MapEntry<WordRange, Ruby> entry in rubyMap.entries) {
      WordRange wordRange = entry.key;
      Ruby ruby = entry.value;

      if (previousEnd + 1 <= wordRange.startIndex.index - 1) {
        WordIndex startIndex = WordIndex(previousEnd + 1);
        WordIndex endIndex = WordIndex(wordRange.startIndex.index - 1);
        wordRangeList.add(
          Tuple2(
            WordRange(startIndex, endIndex),
            null,
          ),
        );
      }
      wordRangeList.add(
        Tuple2(
          wordRange,
          ruby,
        ),
      );

      previousEnd = wordRange.endIndex.index;
    }

    if (previousEnd + 1 <= words.length - 1) {
      WordIndex startIndex = WordIndex(previousEnd + 1);
      WordIndex endIndex = WordIndex(words.length - 1);
      wordRangeList.add(
        Tuple2(
          WordRange(startIndex, endIndex),
          null,
        ),
      );
    }

    return wordRangeList;
  }

  Sentence copyWith({
    VocalistID? vocalistID,
    Timetable? timetable,
    RubyMap? rubyMap,
  }) {
    return Sentence(
      vocalistID: vocalistID ?? this.vocalistID,
      timetable: timetable ?? this.timetable,
      rubyMap: rubyMap ?? this.rubyMap,
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
    return vocalistID == other.vocalistID && timetable == other.timetable && rubyMap == other.rubyMap;
  }

  @override
  int get hashCode => vocalistID.hashCode ^ timetable.hashCode ^ rubyMap.hashCode;
}
