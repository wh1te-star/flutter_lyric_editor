import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/section/section_list.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist_color_map.dart';

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
    switch (type) {
      case LyricUndoType.lyricSnippet:
        assert(value is LyricSnippetMap);
        LyricSnippetMap lyricSnippetMap = value;
        copiedValue = Map<LyricSnippetID, LyricSnippet>.from(lyricSnippetMap.map)..updateAll((key, snippet) => snippet.copyWith());
        break;
      case LyricUndoType.vocalistsColor:
        assert(value is VocalistColorMap);
        VocalistColorMap vocalistColorMap = value;
        copiedValue = Map<VocalistID, Vocalist>.from(vocalistColorMap.map)..updateAll((key, vocalist) => vocalist.copyWith());
        break;
      case LyricUndoType.section:
        assert(value is SectionList);
        SectionList sectionList = value;
        copiedValue = List<int>.from(sectionList.list);
        break;
      default:
        throw ArgumentError('Unsupported LyricUndoType: $type');
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
    assert((type == LyricUndoType.lyricSnippet && value is Map<LyricSnippetID, LyricSnippet>) || (type == LyricUndoType.vocalistsColor && value is Map<VocalistID, Vocalist>) || (type == LyricUndoType.section && value is List<int>), 'Value type does not match the expected type for the given UndoType');
  }
}
