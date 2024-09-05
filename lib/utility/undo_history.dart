import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

enum LyricUndoType {
  lyricSnippet,
  vocalistsColor,
  section,
}

class LyricUndoAction {
  final LyricUndoType type;
  final dynamic value;
  LyricUndoAction(this.type, this.value);
}

class LyricUndoHistory {
  List<LyricUndoAction> undoHistory = [];

  void pushUndoHistory(LyricUndoType type, dynamic value) {
    typeValueAssert(type, value);

    undoHistory.add(LyricUndoAction(type, value));
  }

  LyricUndoAction? popUndoHistory() {
    if (undoHistory.isNotEmpty) {
      return undoHistory.removeLast();
    }
    return null;
  }

  void typeValueAssert(LyricUndoType type, dynamic value) {
    assert((type == LyricUndoType.lyricSnippet && value is Map<SnippetID, LyricSnippet>) || (type == LyricUndoType.vocalistsColor && value is Map<VocalistID, Vocalist>) || (type == LyricUndoType.section && value is List<int>), 'Value type does not match the expected type for the given UndoType');
  }
}
