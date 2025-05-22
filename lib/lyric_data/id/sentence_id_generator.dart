import 'package:lyric_editor/lyric_data/id/sentence_id.dart';

class SentenceIdGenerator {
  int id = 0;

  SentenceID idGen() {
    id += 1;
    return SentenceID(id);
  }
}
