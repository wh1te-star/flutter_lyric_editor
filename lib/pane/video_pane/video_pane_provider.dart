import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/sentence_track.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/sentence_track_map.dart';
import 'package:lyric_editor/pane/video_pane/video_pane.dart';

final videoPaneMasterProvider = ChangeNotifierProvider((ref) {
  return VideoPaneProvider();
});

class VideoPaneProvider with ChangeNotifier {
  DisplayMode displayMode = DisplayMode.appearDissappear;

  VideoPaneProvider();

  void switchDisplayMode() {
    if (displayMode == DisplayMode.appearDissappear) {
      displayMode = DisplayMode.verticalScroll;
    } else {
      displayMode = DisplayMode.appearDissappear;
    }
    notifyListeners();
  }
}
