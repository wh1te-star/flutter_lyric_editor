import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';

class VocalistIdGenerator {
  int id = 1;

  VocalistID idGen() {
    int id = this.id;
    this.id *= 2;
    return VocalistID(id);
  }
}
