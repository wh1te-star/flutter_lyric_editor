import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/show_hide_track.dart';

class ShowHideTrackMap {
  late Map<SentenceID, ShowHideTrack> _map;

  ShowHideTrackMap({
    required SentenceMap lyricSnippetMap,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
    VocalistID? vocalistID,
  }) {
    _map = constructTrackNumberMap(
      sentenceMap: lyricSnippetMap,
      startBulge: startBulge,
      endBulge: endBulge,
      vocalistID: vocalistID,
    );
  }

  Map<SentenceID, ShowHideTrack> get map => _map;

  static ShowHideTrackMap get empty => ShowHideTrackMap(lyricSnippetMap: SentenceMap.empty);
  bool get isEmpty => map.isEmpty;

  int get length => map.length;
  ShowHideTrack operator [](SentenceID lyricSnippetID) => map[lyricSnippetID]!;
  void operator []=(SentenceID key, ShowHideTrack value) {
    map[key] = value;
  }

  Map<SentenceID, ShowHideTrack> constructTrackNumberMap({
    required SentenceMap sentenceMap,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
    VocalistID? vocalistID,
  }) {
    if (vocalistID != null) {
      sentenceMap = sentenceMap.getSentenceByVocalistID(vocalistID);
    }
    if (sentenceMap.isEmpty) return {};

    Map<SentenceID, ShowHideTrack> snippetTracks = {};

    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = sentenceMap.values.first.endTimestamp.position + endBulge.inMilliseconds;
    snippetTracks[sentenceMap.keys.first] = ShowHideTrack(0);

    for (int index = 1; index < sentenceMap.length; index++) {
      SentenceID currentSnippetID = sentenceMap.keys.toList()[index];
      Sentence currentSnippet = sentenceMap.values.toList()[index];
      int start = currentSnippet.startTimestamp.position - startBulge.inMilliseconds;
      int end = currentSnippet.endTimestamp.position + endBulge.inMilliseconds;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }

      snippetTracks[currentSnippetID] = ShowHideTrack(currentOverlap - 1);
    }

    return snippetTracks;
  }

  int getMaxTrackNumber() {
    return map.values.fold<int>(1, (max, current) => max > current.track ? max : current.track);
  }

  ShowHideTrackMap copyWith({
    required SentenceMap lyricSnippetMap,
  }) {
    return ShowHideTrackMap(lyricSnippetMap: lyricSnippetMap);
  }

  @override
  String toString() {
    return map.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShowHideTrackMap) return false;
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
