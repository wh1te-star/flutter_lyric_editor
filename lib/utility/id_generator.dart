import 'package:lyric_editor/utility/lyric_snippet.dart';

class LyricSnippetIDGenerator {
  int currentID;

  LyricSnippetIDGenerator() : currentID = 1;

  LyricSnippetID genID() {
    int returnID = currentID;
    currentID += 1;
    return LyricSnippetID(returnID);
  }

  void reset() {
    currentID = 1;
  }
}

class VocalistIDGenerator {
  int currentID;

  VocalistIDGenerator() : currentID = 1;

  VocalistID genID() {
    int returnID = currentID;
    currentID *= 2;
    return VocalistID(returnID);
  }

  void reset() {
    currentID = 1;
  }
}
