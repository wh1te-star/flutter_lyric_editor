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

class NotifyVideoPaneWidthLimit {
  double widthLimit;
  NotifyVideoPaneWidthLimit(this.widthLimit);
}

class RequestSwitchDisplayMode {}

enum SnippetEdge {
  start,
  end,
}

class NotifyDisplayModeSwitched {}
