import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/sorted_list.dart';

class RequestKeyboardShortcutEnable {
  bool enable;
  RequestKeyboardShortcutEnable(this.enable);
}

class NotifyKeyboardShortcutEnable {
  bool enable;
  NotifyKeyboardShortcutEnable(this.enable);
}

enum Option {
  former,
  latter,
}

class NotifySelectingSnippets {
  List<SnippetID> snippetIDs;
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
  List<SnippetID> currentSnippets;
  NotifyCurrentSnippets(this.currentSnippets);
}

class NotifyCharCursorPosition {
  int cursorPosition;
  Option option;
  NotifyCharCursorPosition(this.cursorPosition, this.option);
}

class NotifyLineCursorPosition {
  SnippetID cursorSnippetID;
  NotifyLineCursorPosition(this.cursorSnippetID);
}

class NotifyVideoPaneWidthLimit {
  double widthLimit;
  NotifyVideoPaneWidthLimit(this.widthLimit);
}

class RequestMoveUpCharCursor {}

class RequestMoveDownCharCursor {}

class RequestMoveLeftCharCursor {}

class RequestMoveRightCharCursor {}

class RequestTimelineZoomIn {}

class RequestTimelineZoomOut {}

class RequestTimelineCursorMoveLeft {}

class RequestTimelineCursorMoveRight {}

class RequestTimelineCursorMoveUp {}

class RequestTimelineCursorMoveDown {}

class RequestToEnterTextSelectMode {}

class RequestToExitTextSelectMode {}

class RequestSwitchDisplayMode {}

enum SnippetEdge {
  start,
  end,
}

class NotifyDisplayModeSwitched {}
