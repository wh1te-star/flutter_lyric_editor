import 'package:lyric_editor/lyric_data/id/sentence_id.dart';

class LyricSnippetIdGenerator {
  int id = 0;

  LyricSnippetID idGen() {
    id += 1;
    return LyricSnippetID(id);
  }
}
