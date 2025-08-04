import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/!%20old/lyric_data/word/word.dart';
import 'package:lyric_editor/!%20old/lyric_data/word/word_list.dart';
import 'package:lyric_editor/!%20old/lyric_data/timetable.dart';
import 'package:lyric_editor/!%20old/position/seek_position/seek_position.dart';
import 'package:lyric_editor/!%20old/position/word_index.dart';

void main() {
  group('test', () {
    Timetable testData1 = Timetable(
      startTimestamp: SeekPosition(2000),
      wordList: WordList([
        Word("abcde", Duration(milliseconds: 1000)),
        Word("", Duration(milliseconds: 1000)),
        Word("fghij", Duration(milliseconds: 1000)),
        Word("", Duration(milliseconds: 1000)),
        Word("klmno", Duration(milliseconds: 1000)),
        Word("", Duration(milliseconds: 1000)),
        Word("pqrst", Duration(milliseconds: 1000)),
      ]),
    );
    setUp(() {});

    test('Test the getWordIndexFromSeekPosition() function', () {
      WordIndex result;
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(1000));
      expect(result, WordIndex.empty);
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(2500));
      expect(result, WordIndex(0));
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(3500));
      expect(result, WordIndex(1));
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(4500));
      expect(result, WordIndex(2));
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(5500));
      expect(result, WordIndex(3));
      result = testData1.getSeekPositionInfoBySeekPosition(SeekPosition(6500));
      expect(result, WordIndex(4));
    });
  });
}
