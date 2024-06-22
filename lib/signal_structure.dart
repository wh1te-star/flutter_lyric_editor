import 'package:lyric_editor/lyric_snippet.dart';
import 'package:lyric_editor/sorted_list.dart';

class RequestInitAudio {
  String path;
  RequestInitAudio(this.path);
}

class RequestPlayPause {}

class NotifyAudioFileLoaded {
  int millisec;
  NotifyAudioFileLoaded(this.millisec);
}

class RequestRewind {
  int millisec;
  RequestRewind(this.millisec);
}

class RequestForward {
  int millisec;
  RequestForward(this.millisec);
}

class RequestVolumeUp {
  double value;
  RequestVolumeUp(this.value);
}

class RequestVolumeDown {
  double value;
  RequestVolumeDown(this.value);
}

class RequestSpeedUp {
  double rate;
  RequestSpeedUp(this.rate);
}

class RequestSpeedDown {
  double rate;
  RequestSpeedDown(this.rate);
}

class RequestMoveUpCharCursor {}

class RequestMoveDownCharCursor {}

class RequestMoveLeftCharCursor {}

class RequestMoveRightCharCursor {}

class RequestTimelineZoomIn {}

class RequestTimelineZoomOut {}

class RequestToAddLyricTiming {
  String snippetID;
  int characterPosition;
  int seekPosition;
  RequestToAddLyricTiming(
      this.snippetID, this.characterPosition, this.seekPosition);
}

class NotifyTimingPointAdded {
  String snippetID;
  List<TimingPoint> timingPoints;
  NotifyTimingPointAdded(this.snippetID, this.timingPoints);
}

class RequestToDeleteLyricTiming {
  String snippetID;
  int characterPosition;
  RequestToDeleteLyricTiming(this.snippetID, this.characterPosition);
}

class NotifyTimingPointDeletion {
  int characterPosition;
  NotifyTimingPointDeletion(this.characterPosition);
}

class NotifySelectingSnippet {
  String snippetID;
  NotifySelectingSnippet(this.snippetID);
}

class NotifyDeselectingSnippet {
  String snippetID;
  NotifyDeselectingSnippet(this.snippetID);
}

class NotifySelectingVocalist {
  String vocalistName;
  NotifySelectingVocalist(this.vocalistName);
}

class NotifyDeselectingVocalist {
  String vocalistName;
  NotifyDeselectingVocalist(this.vocalistName);
}

class NotifyCurrentSnippets {
  List<LyricSnippet> currentSnippets;
  NotifyCurrentSnippets(this.currentSnippets);
}

class NotifyIsPlaying {
  bool isPlaying;
  NotifyIsPlaying(this.isPlaying);
}

class NotifySeekPosition {
  int seekPosition;
  NotifySeekPosition(this.seekPosition);
}

class NotifyCharCursorPosition {
  int cursorPosition;
  NotifyCharCursorPosition(this.cursorPosition);
}

class NotifyVideoPaneWidthLimit {
  double widthLimit;
  NotifyVideoPaneWidthLimit(this.widthLimit);
}

class NotifyLyricLoaded {
  String rawLyricText;
  NotifyLyricLoaded(this.rawLyricText);
}

class NotifyLyricParsed {
  List<LyricSnippet> lyricSnippetList;
  //SortedList<int> sectionPoints;
  NotifyLyricParsed(this.lyricSnippetList);
}
