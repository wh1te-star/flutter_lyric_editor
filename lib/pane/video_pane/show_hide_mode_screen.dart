import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/pane/video_pane/colored_caption.dart';
import 'package:lyric_editor/position/seek_position.dart';

class ShowHideModeScreen extends StatelessWidget {
  int maxLanes;
  SeekPosition seekPosition;
  ShowHideModeScreen({
    required this.maxLanes,
    required this.seekPosition,
  });

  @override
  Widget build(BuildContext context) {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService
        .getSnippetsAtSeekPosition(
          startBulge: startBulge,
          endBulge: endBulge,
        )
        .map;

    double fontSize = 40.0;
    String fontFamily = "Times New Roman";
    final Map<LyricSnippetID, int> tracks = timingService.getTrackNumber(timingService.lyricSnippetMap.map, startBulge, endBulge);
    List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

    for (int i = 0; i < maxLanes; i++) {
      final LyricSnippetID targetSnippetID = currentSnippets.keys.toList().firstWhere(
            (LyricSnippetID id) => tracks[id] == i,
            orElse: () => LyricSnippetID(0),
          );
      if (targetSnippetID != LyricSnippetID(0)) {
        LyricSnippet targetSnippet = timingService.getLyricSnippetByID(targetSnippetID);
        final Color color = Color(timingService.vocalistColorMap[targetSnippet.vocalistID]!.color);
        content[i] = Expanded(
          child: Center(
            child: ColoredCaption(targetSnippet, seekPosition, color),
          ),
        );
      } else {
        content[i] = Expanded(
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
