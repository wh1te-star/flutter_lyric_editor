import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';

class LyricSnippetIdGenerator {
  int id = 0;

  LyricSnippetID idGen() {
    id += 1;
    return LyricSnippetID(id);
  }
}
