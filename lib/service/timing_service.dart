import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/service/xlrc_parser.dart';
import 'package:lyric_editor/utility/undo_history.dart';
import 'package:tuple/tuple.dart';

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  SentenceMap sentenceMap = SentenceMap({});
  Map<SentenceID, int> sentenceTracks = {};
  VocalistColorMap vocalistColorMap = VocalistColorMap({});
  SectionList sectionList = SectionList([]);

  LyricUndoHistory undoHistory = LyricUndoHistory();

  TimingService({
    required this.musicPlayerProvider,
  });

  /* * * * * * * * * * * * * * * * * *
   SectionList functions
  * * * * * * * * * * * * * * * * * */
  void addSection(SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sectionList);
    sectionList.addSection(seekPosition);
    notifyListeners();
  }

  void removeSection(SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sectionList);
    sectionList.removeSection(seekPosition);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   VocalistColorMap functions
  * * * * * * * * * * * * * * * * * */
  void addVocalist(Vocalist vocalist) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.addVocalist(vocalist);
    notifyListeners();
  }

  void removeVocalistByID(VocalistID vocalistID) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByID(vocalistID);
    notifyListeners();
  }

  void removeVocalistByName(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByName(vocalistName);
    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.changeVocalistName(oldName, newName);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   SentenceMap functions
  * * * * * * * * * * * * * * * * * */
  Sentence getSentenceByID(SentenceID id) {
    return sentenceMap.getSentenceByID(id);
  }

  SentenceMap getSentencesByVocalistID(VocalistID vocalistID) {
    return sentenceMap.getSentenceByVocalistID(vocalistID);
  }

  SentenceMap getSentencesAtSeekPosition({
    SeekPosition? seekPosition,
    VocalistID? vocalistID,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
  }) {
    seekPosition ??= musicPlayerProvider.seekPosition;
    return sentenceMap.getSentencesAtSeekPosition(
      seekPosition: seekPosition,
      vocalistID: vocalistID,
      startBulge: startBulge,
      endBulge: endBulge,
    );
  }

  void addSentence(Sentence sentence) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap.addSentence(sentence);
    notifyListeners();
  }

  void removeSentence(SentenceID sentenceID) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap.removeSentenceByID(sentenceID);
    notifyListeners();
  }

  void editSentence(SentenceID sentenceID, String newSentence) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.editSentence(sentenceID, newSentence);
    notifyListeners();
  }

  void addRuby(SentenceID sentenceID, WordRange wordRange, String rubyString) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.addRuby(sentenceID, wordRange, rubyString);
    notifyListeners();
  }

  void removeRuby(SentenceID sentenceID, WordRange wordRange) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.removeRuby(sentenceID, wordRange);
    notifyListeners();
  }

  void addTiming(SentenceID sentenceID, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.addTiming(sentenceID, charPosition, seekPosition);
    notifyListeners();
  }

  void removeTiming(SentenceID sentenceID, InsertionPosition charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.removeTiming(sentenceID, charPosition, option);
    notifyListeners();
  }

  void addRubyTiming(SentenceID sentenceID, WordRange wordRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.addRubyTiming(sentenceID, wordRange, charPosition, seekPosition);
    notifyListeners();
  }

  void removeRubyTiming(SentenceID sentenceID, WordRange wordRange, InsertionPosition charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.removeRubyTiming(sentenceID, wordRange, charPosition, option);
    notifyListeners();
  }

  void manipulateSentence(SentenceID sentenceID, SentenceSide sentenceSide, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.manipulateSentence(sentenceID, musicPlayerProvider.seekPosition, sentenceSide, holdLength);
    notifyListeners();
  }

  void divideSentence(SentenceID sentenceID, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.divideSentence(sentenceID, charPosition, seekPosition);
    notifyListeners();
  }

  void concatenateSentences(SentenceID firstSentenceID, SentenceID secondSentenceID) {
    undoHistory.pushUndoHistory(LyricUndoType.sentence, sentenceMap);
    sentenceMap = sentenceMap.concatenateSentences(firstSentenceID, secondSentenceID);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   Change Notifier's Original functions
  * * * * * * * * * * * * * * * * * */
  void importLyric(String importPath) async {
    File file = File(importPath);
    String rawText = await file.readAsString();

    XlrcParser parser = XlrcParser();
    Tuple3<SentenceMap, VocalistColorMap, SectionList> data = parser.deserialize(rawText);
    sentenceMap = data.item1;
    vocalistColorMap = data.item2;
    sectionList = data.item3;

    notifyListeners();
  }

  void exportLyric(String exportPath) {
    XlrcParser parser = XlrcParser();
    Tuple3<SentenceMap, VocalistColorMap, SectionList> data = Tuple3<SentenceMap, VocalistColorMap, SectionList>(
      sentenceMap,
      vocalistColorMap,
      sectionList,
    );
    String rawText = parser.serialize(data);

    File file = File(exportPath);
    file.writeAsStringSync(rawText);
  }

  void undo() {
    LyricUndoAction? action = undoHistory.popUndoHistory();
    if (action != null) {
      LyricUndoType type = action.type;
      dynamic value = action.value;

      if (type == LyricUndoType.sentence) {
        sentenceMap = value;
      } else if (type == LyricUndoType.vocalistsColor) {
        vocalistColorMap = value;
      } else {
        sectionList = value;
      }
    }

    notifyListeners();
  }
}