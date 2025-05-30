import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id_generator.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class SentenceMap {
  final Map<SentenceID, Sentence> _sentenceMap;
  static final SentenceIdGenerator idGenerator = SentenceIdGenerator();

  SentenceMap(this._sentenceMap) {
    assert(isSentencesOrdered());
  }

  Map<SentenceID, Sentence> get map => _sentenceMap;

  bool isSentencesOrdered() {
    return map.values.map((Sentence sentence) {
      return sentence.startTimestamp.absolute;
    }).isSorted((AbsoluteSeekPosition left, AbsoluteSeekPosition right) => left.compareTo(right));
  }

  static SentenceMap get empty => SentenceMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<SentenceID, Sentence>> get entries => map.entries;
  Iterable<SentenceID> get keys => map.keys;
  Iterable<Sentence> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(SentenceID key) => map.containsKey(key);
  Sentence? operator [](SentenceID key) => map[key];
  void operator []=(SentenceID key, Sentence value) {
    map[key] = value;
  }

  Sentence getSentenceByID(SentenceID id) {
    if (!map.containsKey(id)) {
      return Sentence.empty;
    }
    return map[id]!;
  }

  SentenceMap getSentenceByVocalistID(VocalistID vocalistID) {
    final Iterable<MapEntry<SentenceID, Sentence>> filteredEntries = map.entries.where((MapEntry<SentenceID, Sentence> entry) => entry.value.vocalistID == vocalistID);
    return SentenceMap(Map.fromEntries(filteredEntries));
  }

  SentenceMap sortSentenceList(SentenceMap sentenceMap) {
    return SentenceMap(Map.fromEntries(
      sentenceMap.map.entries.toList()
        ..sort(
          (MapEntry<SentenceID, Sentence> left, MapEntry<SentenceID, Sentence> right) {
            AbsoluteSeekPosition leftStartTimestamp = left.value.startTimestamp;
            AbsoluteSeekPosition rightStartTimestamp = right.value.startTimestamp;
            int compareStartTime = leftStartTimestamp.compareTo(rightStartTimestamp);
            if (compareStartTime != 0) {
              return compareStartTime;
            }

            int leftVocalistID = left.value.vocalistID.id;
            int rightVocalistID = right.value.vocalistID.id;
            int compareVocalistID = leftVocalistID.compareTo(rightVocalistID);
            return compareVocalistID;
          },
        ),
    ));
  }

  SentenceMap addSentence(Sentence sentence) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    copiedMap[idGenerator.idGen()] = sentence;
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeSentenceByID(SentenceID id) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    copiedMap.remove(id);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap editSentence(SentenceID id, String newSentence) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.editSentence(newSentence);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addRuby(SentenceID id, WordRange wordRange, String rubyString) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addRuby(wordRange, rubyString);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeRuby(SentenceID id, WordRange wordRange) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeRuby(wordRange);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addTiming(SentenceID id, CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    map[id] = map[id]!.addTiming(charPosition, seekPosition);
    return SentenceMap(map);
  }

  SentenceMap removeTiming(SentenceID id, CaretPosition charPosition, Option option) {
    Sentence sentence = map[id]!;
    sentence = sentence.removeTiming(charPosition, option);
    return SentenceMap(map);
  }

  SentenceMap addRubyTiming(SentenceID id, WordRange wordRange, CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addRubyTiming(wordRange, charPosition, seekPosition);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeRubyTiming(SentenceID id, WordRange wordRange, CaretPosition charPosition, Option option) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeRubyTiming(wordRange, charPosition, option);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap manipulateSentence(SentenceID id, AbsoluteSeekPosition seekPosition, SentenceSide sentenceSide, bool holdLength) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.manipulateSentence(seekPosition, sentenceSide, holdLength);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap divideSentence(SentenceID id, CaretPosition charPosition, AbsoluteSeekPosition seekPosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    Tuple2<Sentence, Sentence> dividedSentences = sentence.divideSentence(charPosition, seekPosition);
    copiedMap.remove(id);
    for (var sentence in [dividedSentences.item1, dividedSentences.item2]) {
      if (!sentence.isEmpty) {
        copiedMap[idGenerator.idGen()] = sentence;
      }
    }
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap concatenateSentences(SentenceID firstSentenceID, SentenceID secondSentenceID) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);

    SentenceID formerSentenceID = firstSentenceID;
    SentenceID latterSentenceID = secondSentenceID;
    Sentence formerSentence = map[formerSentenceID]!;
    Sentence latterSentence = map[latterSentenceID]!;

    if (formerSentence.vocalistID != latterSentence.vocalistID) {
      throw Exception("The vocalist must be the same.");
    }

    if (latterSentence.startTimestamp < formerSentence.startTimestamp) {
      _swap(formerSentence, latterSentence);
    }

    WordList concatenatedWordList = formerSentence.timetable.wordList.copyWith();
    Duration bondPointDuration = Duration(milliseconds: latterSentence.startTimestamp.position - formerSentence.endTimestamp.position);
    int indexCarryUp = formerSentence.timetable.wordList.list.length;
    if (bondPointDuration > Duration.zero) {
      concatenatedWordList = concatenatedWordList.addWord(Word("", bondPointDuration));
      indexCarryUp++;
    }
    concatenatedWordList += latterSentence.timetable.wordList;

    RubyMap concatenatedRubyMap = formerSentence.rubyMap.concatenate(indexCarryUp, latterSentence.rubyMap);

    copiedMap.remove(formerSentenceID);
    copiedMap.remove(latterSentenceID);
    copiedMap[idGenerator.idGen()] = Sentence(
      vocalistID: formerSentence.vocalistID,
      timetable: Timetable(
        startTimestamp: formerSentence.startTimestamp,
        wordList: concatenatedWordList,
      ),
      rubyMap: concatenatedRubyMap,
    );

    return sortSentenceList(SentenceMap(copiedMap));
  }

  void _swap(Sentence sentence1, Sentence sentence2) {
    final Sentence temp = sentence1;
    sentence1 = sentence2;
    sentence2 = temp;
  }

  SentenceMap getSentencesAtSeekPosition({
    required AbsoluteSeekPosition seekPosition,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
    VocalistID? vocalistID,
  }) {
    final Iterable<MapEntry<SentenceID, Sentence>> filteredEntries = map.entries.where((MapEntry<SentenceID, Sentence> entry) {
      SentenceID sentenceID = entry.key;
      Sentence sentence = entry.value;
      SeekPosition expandedStartTimestamp = sentence.startTimestamp - startBulge;
      SeekPosition expandedEndTimestamp = sentence.endTimestamp + endBulge;
      bool isWithinTimestamp = expandedStartTimestamp.absolute <= seekPosition && seekPosition <= expandedEndTimestamp.absolute;
      bool isMatchingVocalist = vocalistID == null || entry.value.vocalistID == vocalistID;
      return isWithinTimestamp && isMatchingVocalist;
    });

    return SentenceMap(Map.fromEntries(filteredEntries));
  }

  SentenceMap copyWith({
    Map<SentenceID, Sentence>? sentenceMap,
  }) {
    return SentenceMap({...(sentenceMap ?? map)}.map((key, value) => MapEntry(key, value.copyWith())));
  }

  @override
  String toString() {
    return map.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SentenceMap) return false;
    if (map.length != other.map.length) return false;
    return map.keys.every((key) {
      return map[key] == other.map[key];
    });
  }

  @override
  int get hashCode => map.entries.fold(0, (hash, entry) {
        return hash ^ entry.key.hashCode ^ entry.value.hashCode;
      });
}
