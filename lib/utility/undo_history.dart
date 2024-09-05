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
    final dynamic copiedValue;
    if (type == LyricUndoType.lyricSnippet) {
      assert(value is Map<SnippetID, LyricSnippet>);
      copiedValue = Map<SnippetID, LyricSnippet>.from(value)
        ..updateAll((key, snippet) => snippet.copyWith());
    } else if (type == LyricUndoType.vocalistsColor) {
      assert(value is Map<VocalistID, Vocalist>);
      copiedValue = Map<VocalistID, Vocalist>.from(value)
        ..updateAll((key, vocalist) => vocalist.copyWith());
    } else {
      assert(value is List<int>);
      copiedValue = List<int>.from(value);
    }

    undoHistory.add(LyricUndoAction(type, copiedValue));
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
