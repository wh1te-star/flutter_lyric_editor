import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/lyric_data/timing/timing_list.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';

class WordList {
  final List<Word> _list;

  WordList(this._list) {
    assert(!has2ConseqentEmpty());
  }

  List<Word> get list => _list;

  static WordList get empty => WordList([]);
  bool get isEmpty => list.isEmpty;

  int get length => list.length;
  Word operator [](WordIndex index) => list[index.index];
  void operator []=(WordIndex index, Word value) {
    list[index.index] = value;
  }

  String get sentence {
    return _list.map((Word word) {
      return word.word;
    }).join("");
  }

  int get wordCount => list.length;
  int get charCount {
    return list.fold(0, (total, word) {
      return total + word.word.length;
    });
  }

  bool has2ConseqentEmpty() {
    for (int index = 0; index < _list.length - 1; index++) {
      if (_list[index].word == "" && _list[index + 1].word == "") {
        return true;
      }
    }
    return false;
  }

  TimingList toTimingList() {
    List<Timing> timings = [];
    CaretPosition caretPosition = CaretPosition(0);
    SeekPosition seekPosition = SeekPosition(0);
    for (Word word in list) {
      timings.add(Timing(caretPosition, seekPosition));

      caretPosition += word.word.length;
      seekPosition += word.duration;
    }
    timings.add(Timing(caretPosition, seekPosition));

    return TimingList(timings);
  }

  WordList copyWith({
    WordList? wordList,
  }) {
    return WordList(
      wordList?._list.map((Word word) => word.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  WordList operator +(WordList other) {
    List<Word> combinedList = [..._list, ...other._list];
    return WordList(combinedList);
  }

  WordList addWord(Word word) {
    List<Word> combinedList = [..._list, word];
    return WordList(combinedList);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, Word> entry) {
      int index = entry.key;
      Word timing = entry.value;
      return timing == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
