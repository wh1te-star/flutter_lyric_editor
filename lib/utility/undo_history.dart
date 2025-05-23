import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';

enum LyricUndoType {
  sentence,
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
      case LyricUndoType.sentence:
        assert(value is SentenceMap);
        SentenceMap sentenceMap = value;
        copiedValue = Map<SentenceID, Sentence>.from(sentenceMap.map)..updateAll((key, sentence) => sentence.copyWith());
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
    assert((type == LyricUndoType.sentence && value is Map<SentenceID, Sentence>) || (type == LyricUndoType.vocalistsColor && value is Map<VocalistID, Vocalist>) || (type == LyricUndoType.section && value is List<int>), 'Value type does not match the expected type for the given UndoType');
  }
}
