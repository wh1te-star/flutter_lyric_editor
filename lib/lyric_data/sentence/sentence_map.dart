import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id_generator.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';
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
      return sentence.timetable.startTimestamp;
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
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.editSentence(newSentence);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addRuby(SentenceID id, PhrasePosition phrasePosition, String rubyString) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addRuby(phrasePosition, rubyString);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeRuby(SentenceID id, PhrasePosition phrasePosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeRuby(phrasePosition);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap addTimingPoint(SentenceID id, InsertionPosition charPosition, SeekPosition seekPosition) {
    map[id] = map[id]!.addTimingPoint(charPosition, seekPosition);
    return SentenceMap(map);
  }

  SentenceMap removeTimingPoint(SentenceID id, InsertionPosition charPosition, Option option) {
    Sentence sentence = map[id]!;
    sentence = sentence.removeTimingPoint(charPosition, option);
    return SentenceMap(map);
  }

  SentenceMap addRubyTimingPoint(SentenceID id, PhrasePosition phrasePosition, InsertionPosition charPosition, SeekPosition seekPosition) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.addRubyTimingPoint(phrasePosition, charPosition, seekPosition);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap removeRubyTimingPoint(SentenceID id, PhrasePosition phrasePosition, InsertionPosition charPosition, Option option) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.removeRubyTimingPoint(phrasePosition, charPosition, option);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap manipulateSentence(SentenceID id, SeekPosition seekPosition, SentenceEdge sentenceEdge, bool holdLength) {
    final Map<SentenceID, Sentence> copiedMap = Map<SentenceID, Sentence>.from(map);
    Sentence sentence = copiedMap[id]!;
    sentence = sentence.manipulateSentence(seekPosition, sentenceEdge, holdLength);
    return sortSentenceList(SentenceMap(copiedMap));
  }

  SentenceMap divideSentence(SentenceID id, InsertionPosition charPosition, SeekPosition seekPosition) {
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

    SentenceSegmentList concatenatedSentenceSegmentList = formerSentence.timetable.sentenceSegmentList.copyWith();
    Duration bondPointDuration = Duration(milliseconds: latterSentence.startTimestamp.position - formerSentence.endTimestamp.position);
    int indexCarryUp = formerSentence.timetable.sentenceSegmentList.list.length;
    if (bondPointDuration > Duration.zero) {
      concatenatedSentenceSegmentList = concatenatedSentenceSegmentList.addSegment(SentenceSegment("", bondPointDuration));
      indexCarryUp++;
    }
    concatenatedSentenceSegmentList += latterSentence.timetable.sentenceSegmentList;

    RubyMap concatenatedRubyMap = formerSentence.rubyMap.concatenate(indexCarryUp, latterSentence.rubyMap);

    copiedMap.remove(formerSentenceID);
    copiedMap.remove(latterSentenceID);
    copiedMap[idGenerator.idGen()] = Sentence(
      vocalistID: formerSentence.vocalistID,
      timetable: Timetable(
        startTimestamp: formerSentence.startTimestamp,
        sentenceSegmentList: concatenatedSentenceSegmentList,
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
