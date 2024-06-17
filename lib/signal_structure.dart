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

class RequestToAddLyricTiming {
  int characterPosition;
  int seekPosition;
  RequestToAddLyricTiming(this.characterPosition, this.seekPosition);
}

class NotifyTimingPointAdded {
  int characterPosition;
  NotifyTimingPointAdded(this.characterPosition);
}

class RequestToDeleteLyricTiming {
  int characterPosition;
  RequestToDeleteLyricTiming(this.characterPosition);
}

class NotifyTimingPointDeletion {
  int characterPosition;
  NotifyTimingPointDeletion(this.characterPosition);
}

class NotifyIsPlaying {
  bool isPlaying;
  NotifyIsPlaying(this.isPlaying);
}

class NotifySeekPosition {
  int seekPosition;
  NotifySeekPosition(this.seekPosition);
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
