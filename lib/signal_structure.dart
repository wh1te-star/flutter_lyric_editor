import 'package:lyric_editor/sorted_list.dart';

class RequestPlayPause {}

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
  RequestToAddLyricTiming(this.characterPosition);
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
  String entireLyricString;
  SortedList<int> timingPoints;
  SortedList<int> linefeedPoints;
  //SortedList<int> sectionPoints;
  NotifyLyricParsed(
      this.entireLyricString, this.timingPoints, this.linefeedPoints);
}
