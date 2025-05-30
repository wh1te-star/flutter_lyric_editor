import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/pane/video_pane/colored_caption.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/sentence_track.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/sentence_track_map.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class ShowHideModeScreen extends StatelessWidget {
  Duration startBulge = const Duration(milliseconds: 1000);
  Duration endBulge = const Duration(milliseconds: 1000);

  SentenceMap sentenceMap;
  VocalistColorMap vocalistColorMap;
  SeekPosition seekPosition;
  ShowHideModeScreen({
    required this.sentenceMap,
    required this.vocalistColorMap,
    required this.seekPosition,
  });

  @override
  Widget build(BuildContext context) {
    ShowHideTrackMap showHideTrackMap = ShowHideTrackMap(
      sentenceMap: sentenceMap,
      startBulge: startBulge,
      endBulge: endBulge,
    );
    SentenceMap currentSentences = sentenceMap.getSentencesAtSeekPosition(
      seekPosition: seekPosition.absolute,
      startBulge: startBulge,
      endBulge: endBulge,
    );

    double fontSize = 40.0;
    String fontFamily = "Times New Roman";
    int maxLanes = showHideTrackMap.getMaxTrackNumber();
    List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

    for (int index = 0; index < maxLanes; index++) {
      final SentenceID targetSentenceID = currentSentences.keys.toList().firstWhere(
            (SentenceID id) => showHideTrackMap[id].track == index,
            orElse: () => SentenceID.empty,
          );
      if (targetSentenceID != SentenceID.empty) {
        Sentence targetSentence = sentenceMap[targetSentenceID]!;
        final Color color = Color(vocalistColorMap[targetSentence.vocalistID]!.color);
        content[index] = Expanded(
          child: Center(
            child: ColoredCaption(targetSentence, seekPosition, color),
          ),
        );
      } else {
        content[index] = Expanded(
          child: Center(
            child: Container(color: Colors.transparent),
          ),
        );
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: content,
    );
  }
}
