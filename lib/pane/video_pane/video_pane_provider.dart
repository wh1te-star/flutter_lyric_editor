import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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