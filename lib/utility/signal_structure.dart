import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/sorted_list.dart';

class RequestInitAudio {
  String path;
  RequestInitAudio({this.path = ""});
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

class RequestInitLyric {
  String path;
  String lyric;
  RequestInitLyric({this.path = "", this.lyric = ""});
}

class RequestLoadLyric {
  String path;
  String lyric;
  RequestLoadLyric({this.path = "", this.lyric = ""});
}

class RequestExportLyric {
  String path;
  String lyric;
  RequestExportLyric({this.path = "", this.lyric = ""});
}

class RequestAddVocalist {
  String vocalistName;
  RequestAddVocalist(this.vocalistName);
}

class RequestDeleteVocalist {
  String vocalistName;
  RequestDeleteVocalist(this.vocalistName);
}

class RequestChangeVocalistName {
  String oldName;
  String newName;
  RequestChangeVocalistName(this.oldName, this.newName);
}

class RequestToAddLyricTiming {
  LyricSnippetID snippetID;
  int characterPosition;
  int seekPosition;
  RequestToAddLyricTiming(
      this.snippetID, this.characterPosition, this.seekPosition);
}

class NotifyTimingPointAdded {
  LyricSnippetID snippetID;
  List<TimingPoint> timingPoints;
  NotifyTimingPointAdded(this.snippetID, this.timingPoints);
}

class RequestToDeleteLyricTiming {
  LyricSnippetID snippetID;
  int characterPosition;
  Choice choice = Choice.former;
  RequestToDeleteLyricTiming(this.snippetID, this.characterPosition,
      {this.choice = Choice.former});
}

enum Choice {
  former,
  latter,
}

class NotifyVocalistNameAdded {
  List<LyricSnippet> lyricSnippetList;
  NotifyVocalistNameAdded(this.lyricSnippetList);
}

class NotifyVocalistDeleted {
  List<LyricSnippet> lyricSnippetList;
  NotifyVocalistDeleted(this.lyricSnippetList);
}

class NotifyVocalistNameChanged {
  List<LyricSnippet> lyricSnippetList;
  NotifyVocalistNameChanged(this.lyricSnippetList);
}

class NotifyTimingPointDeletion {
  int characterPosition;
  NotifyTimingPointDeletion(this.characterPosition);
}

class NotifySelectingSnippets {
  List<LyricSnippetID> snippetIDs;
  NotifySelectingSnippets(this.snippetIDs);
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
  List<LyricSnippetID> currentSnippets;
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

class NotifyLineCursorPosition {
  LyricSnippetID cursorSnippetID;
  NotifyLineCursorPosition(this.cursorSnippetID);
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

class RequestMoveUpCharCursor {}

class RequestMoveDownCharCursor {}

class RequestMoveLeftCharCursor {}

class RequestMoveRightCharCursor {}

class RequestTimelineZoomIn {}

class RequestTimelineZoomOut {}

class RequestToEnterTextSelectMode {}

class RequestToExitTextSelectMode {}

class RequestDivideSnippet {
  LyricSnippetID snippetID;
  int charPos;
  RequestDivideSnippet(this.snippetID, this.charPos);
}

class RequestConcatenateSnippet {
  List<LyricSnippetID> snippetIDs;
  RequestConcatenateSnippet(this.snippetIDs);
}

class NotifySnippetDivided {
  List<LyricSnippet> lyricSnippetList;
  NotifySnippetDivided(this.lyricSnippetList);
}

class NotifySnippetConcatenated {
  List<LyricSnippet> lyricSnippetList;
  NotifySnippetConcatenated(this.lyricSnippetList);
}

enum SnippetEdge {
  start,
  end,
}

class RequestSnippetMove {
  LyricSnippetID id;
  SnippetEdge snippetEdge;
  bool holdLength;
  RequestSnippetMove(this.id, this.snippetEdge, this.holdLength);
}

class NotifySnippetMove {
  List<LyricSnippet> lyricSnippetList;
  NotifySnippetMove(this.lyricSnippetList);
}
