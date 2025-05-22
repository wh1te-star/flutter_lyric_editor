import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id_generator.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
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
      return sentence.timeline.startTime;
    }).isSorted((SeekPosition left, SeekPosition right) => left.compareTo(right));
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
            SeekPosition leftStartTimestamp = left.value.startTimestamp;
            SeekPosition rightStartTimestamp = right.value.startTimestamp;
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
    Sentence lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.editSentence(newSentence);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addReadng(SentenceID id, PhrasePosition phrase, String readingString) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addReading(phrase, readingString);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeReading(SentenceID id, PhrasePosition phrase) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeReading(phrase);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addTimingPoint(SentenceID id, InsertionPosition insertionPosition, SeekPosition seekPosition) {
    map[id] = map[id]!.addTimingPoint(insertionPosition, seekPosition);
    return SentenceMap(map);
  }

  SentenceMap removeTimingPoint(SentenceID id, InsertionPosition insertionPosition, Option option) {
    Sentence lyricSnippet = map[id]!;
    lyricSnippet = lyricSnippet.removeTimingPoint(insertionPosition, option);
    return SentenceMap(map);
  }

  SentenceMap addReadingTimingPoint(SentenceID id, PhrasePosition phrase, InsertionPosition insertionPosition, SeekPosition seekPosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addReadingTiming(phrase, insertionPosition, seekPosition);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeReadingTiming(SentenceID id, PhrasePosition phrase, InsertionPosition insertionPosition, Option option) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeReadingTiming(phrase, insertionPosition, option);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap manipulateSentence(SentenceID id, SeekPosition seekPosition, SentenceEdge sentenceEdge, bool holdLength) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.manipulateSnippet(seekPosition, sentenceEdge, holdLength);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap divideSentence(SentenceID id, InsertionPosition charPosition, SeekPosition seekPosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence lyricSnippet = copiedMap[id]!;
    Tuple2<Sentence, Sentence> dividedSentences = lyricSnippet.dividSnippet(charPosition, seekPosition);
    copiedMap.remove(id);
    for (var snippet in [dividedSentences.item1, dividedSentences.item2]) {
      if (!snippet.isEmpty) {
        copiedMap[idGenerator.idGen()] = snippet;
      }
    }
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap concatenateSnippets(SentenceID firstSentenceID, SentenceID secondSentenceID) {
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

    WordList concatenatedWordList = formerSentence.timeline.wordList.copyWith();
    Duration bondPointDuration = Duration(milliseconds: latterSentence.startTimestamp.position - formerSentence.endTimestamp.position);
    int indexCarryUp = formerSentence.timeline.wordList.list.length;
    if (bondPointDuration > Duration.zero) {
      concatenatedWordList = concatenatedWordList.addSegment(Word("", bondPointDuration));
      indexCarryUp++;
    }
    concatenatedWordList += latterSentence.timeline.wordList;

    ReadingMap concatenatedReadingMap = formerSentence.readingMap.concatenate(indexCarryUp, latterSentence.readingMap);

    copiedMap.remove(formerSentenceID);
    copiedMap.remove(latterSentenceID);
    copiedMap[idGenerator.idGen()] = Sentence(
      vocalistID: formerSentence.vocalistID,
      timeline: Timeline(
        startTime: formerSentence.startTimestamp,
        wordList: concatenatedWordList,
      ),
      readingMap: concatenatedReadingMap,
    );

    return sortSentenceList(SentenceMap(copiedMap));
  }

  void _swap(Sentence snippet1, Sentence snippet2) {
    final Sentence temp = snippet1;
    snippet1 = snippet2;
    snippet2 = temp;
  }

  SentenceMap getSnippetsAtSeekPosition({
    required SeekPosition seekPosition,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
    VocalistID? vocalistID,
  }) {
    final Iterable<MapEntry<SentenceID, Sentence>> filteredEntries = map.entries.where((MapEntry<SentenceID, Sentence> entry) {
      bool isWithinTimestamp = entry.value.startTimestamp.position - startBulge.inMilliseconds <= seekPosition.position && seekPosition.position <= entry.value.endTimestamp.position + endBulge.inMilliseconds;
      bool isMatchingVocalist = vocalistID == null || entry.value.vocalistID == vocalistID;
      return isWithinTimestamp && isMatchingVocalist;
    });

    return SentenceMap(Map.fromEntries(filteredEntries));
  }

  SentenceMap copyWith({
    Map<SentenceID, Sentence>? lyricSnippetMap,
  }) {
    return SentenceMap({...(lyricSnippetMap ?? map)}.map((key, value) => MapEntry(key, value.copyWith())));
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
