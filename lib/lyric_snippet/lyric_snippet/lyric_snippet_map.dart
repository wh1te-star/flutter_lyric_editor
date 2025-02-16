import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id_generator.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:tuple/tuple.dart';

class LyricSnippetMap {
  final Map<LyricSnippetID, LyricSnippet> _lyricSnippetMap;
  static final LyricSnippetIdGenerator idGenerator = LyricSnippetIdGenerator();

  LyricSnippetMap(this._lyricSnippetMap) {
    assert(isLyricSnippetsOrdered());
  }

  Map<LyricSnippetID, LyricSnippet> get map => _lyricSnippetMap;

  bool isLyricSnippetsOrdered() {
    return map.values.map((LyricSnippet lyricSnippet) {
      return lyricSnippet.timing.startTimestamp;
    }).isSorted((SeekPosition left, SeekPosition right) => left.compareTo(right));
  }

  static LyricSnippetMap get empty => LyricSnippetMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<LyricSnippetID, LyricSnippet>> get entries => map.entries;
  Iterable<LyricSnippetID> get keys => map.keys;
  Iterable<LyricSnippet> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(LyricSnippetID key) => map.containsKey(key);
  LyricSnippet? operator [](LyricSnippetID key) => map[key];
  void operator []=(LyricSnippetID key, LyricSnippet value) {
    map[key] = value;
  }

  LyricSnippet getLyricSnippetByID(LyricSnippetID id) {
    return map[id]!;
  }

  LyricSnippetMap getLyricSnippetByVocalistID(VocalistID vocalistID) {
    final Iterable<MapEntry<LyricSnippetID, LyricSnippet>> filteredEntries = map.entries.where((MapEntry<LyricSnippetID, LyricSnippet> entry) => entry.value.vocalistID == vocalistID);
    return LyricSnippetMap(Map.fromEntries(filteredEntries));
  }

  LyricSnippetMap sortLyricSnippetList(LyricSnippetMap lyricSnippetMap) {
    return LyricSnippetMap(Map.fromEntries(
      lyricSnippetMap.map.entries.toList()
        ..sort(
          (MapEntry<LyricSnippetID, LyricSnippet> left, MapEntry<LyricSnippetID, LyricSnippet> right) {
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

  LyricSnippetMap addLyricSnippet(LyricSnippet lyricSnippet) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    copiedMap[idGenerator.idGen()] = lyricSnippet;
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap removeLyricSnippetByID(LyricSnippetID id) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    copiedMap.remove(id);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap editSentence(LyricSnippetID id, String newSentence) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.editSentence(newSentence);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap addAnnotation(LyricSnippetID id, SegmentRange segmentRange, String annotationString) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.addAnnotation(segmentRange, annotationString);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap removeAnnotation(LyricSnippetID id, SegmentRange segmentRange) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.removeAnnotation(segmentRange);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap addTimingPoint(LyricSnippetID id, InsertionPosition charPosition, SeekPosition seekPosition) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.addTimingPoint(charPosition, seekPosition);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap removeTimingPoint(LyricSnippetID id, InsertionPosition charPosition, Option option) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.removeTimingPoint(charPosition, option);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap addAnnotationTimingPoint(LyricSnippetID id, SegmentRange segmentRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.addAnnotationTimingPoint(segmentRange, charPosition, seekPosition);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap removeAnnotationTimingPoint(LyricSnippetID id, SegmentRange segmentRange, InsertionPosition charPosition, Option option) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.removeAnnotationTimingPoint(segmentRange, charPosition, option);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap manipulateSnippet(LyricSnippetID id, SeekPosition seekPosition, SnippetEdge snippetEdge, bool holdLength) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    lyricSnippet = lyricSnippet.manipulateSnippet(seekPosition, snippetEdge, holdLength);
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap divideSnippet(LyricSnippetID id, InsertionPosition charPosition, SeekPosition seekPosition) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);
    LyricSnippet lyricSnippet = copiedMap[id]!;
    Tuple2<LyricSnippet, LyricSnippet> dividedLyricSnippets = lyricSnippet.dividSnippet(charPosition, seekPosition);
    copiedMap.remove(id);
    for (var snippet in [dividedLyricSnippets.item1, dividedLyricSnippets.item2]) {
      if (!snippet.isEmpty) {
        copiedMap[idGenerator.idGen()] = snippet;
      }
    }
    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  LyricSnippetMap concatenateSnippets(LyricSnippetID firstLyricSnippetID, LyricSnippetID secondLyricSnippetID) {
    final Map<LyricSnippetID, LyricSnippet> copiedMap = Map<LyricSnippetID, LyricSnippet>.from(map);

    LyricSnippetID formerSnippetID = firstLyricSnippetID;
    LyricSnippetID latterSnippetID = secondLyricSnippetID;
    LyricSnippet formerSnippet = map[formerSnippetID]!;
    LyricSnippet latterSnippet = map[latterSnippetID]!;

    if (formerSnippet.vocalistID != latterSnippet.vocalistID) {
      throw Exception("The vocalist must be the same.");
    }

    if (latterSnippet.startTimestamp < formerSnippet.startTimestamp) {
      _swap(formerSnippet, latterSnippet);
    }

    SentenceSegmentList concatenatedSentenceSegmentList = formerSnippet.timing.sentenceSegmentList.copyWith();
    Duration bondPointDuration =Duration(milliseconds: latterSnippet.startTimestamp.position - formerSnippet.endTimestamp.position);
    int indexCarryUp = formerSnippet.timing.sentenceSegmentList.list.length;
    if (bondPointDuration > Duration.zero) {
      concatenatedSentenceSegmentList = concatenatedSentenceSegmentList.addSegment(SentenceSegment("", bondPointDuration));
      indexCarryUp++;
    }
    concatenatedSentenceSegmentList += latterSnippet.timing.sentenceSegmentList;

    AnnotationMap concatenatedAnnotationMap = formerSnippet.annotationMap.concatenate(indexCarryUp, latterSnippet.annotationMap);

    copiedMap.remove(formerSnippetID);
    copiedMap.remove(latterSnippetID);
    copiedMap[idGenerator.idGen()] = LyricSnippet(
      vocalistID: formerSnippet.vocalistID,
      timing: Timing(
        startTimestamp: formerSnippet.startTimestamp,
        sentenceSegmentList: concatenatedSentenceSegmentList,
      ),
      annotationMap: concatenatedAnnotationMap,
    );

    return sortLyricSnippetList(LyricSnippetMap(copiedMap));
  }

  void _swap(LyricSnippet snippet1, LyricSnippet snippet2) {
    final LyricSnippet temp = snippet1;
    snippet1 = snippet2;
    snippet2 = temp;
  }

  LyricSnippetMap getSnippetsAtSeekPosition({
    required SeekPosition seekPosition,
    VocalistID? vocalistID,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
  }) {
    final Iterable<MapEntry<LyricSnippetID, LyricSnippet>> filteredEntries = map.entries.where((MapEntry<LyricSnippetID, LyricSnippet> entry) {
      bool isWithinTimestamp = entry.value.startTimestamp.position - startBulge.inMilliseconds <= seekPosition.position && seekPosition.position <= entry.value.endTimestamp.position + endBulge.inMilliseconds;
      bool isMatchingVocalist = vocalistID == null || entry.value.vocalistID == vocalistID;
      return isWithinTimestamp && isMatchingVocalist;
    });

    return LyricSnippetMap(Map.fromEntries(filteredEntries));
  }

  LyricSnippetMap copyWith({
    Map<LyricSnippetID, LyricSnippet>? lyricSnippetMap,
  }) {
    return LyricSnippetMap({...(lyricSnippetMap ?? map)}.map((key, value) => MapEntry(key, value.copyWith())));
  }

  @override
  String toString() {
    return map.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LyricSnippetMap) return false;
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
