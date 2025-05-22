import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

void main() {
  group('Tests to add and delete a timing point.', () {
    final Timeline dataSet1 = Timeline(
      startTime: SeekPosition(2000),
      wordList: WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fghijk", const Duration(milliseconds: 700)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]),
    );
    final Timeline dataSet2 = Timeline(
      startTime: SeekPosition(5000),
      wordList: WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]),
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {});

    test('Test to add a timing point No.1', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(7);
      final SeekPosition seekPosition = SeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fg", const Duration(milliseconds: 50)),
        Word("hijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point No.2', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(8);
      final SeekPosition seekPosition = SeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fgh", const Duration(milliseconds: 50)),
        Word("ijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test the seek position is not valid', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(8);
      final SeekPosition seekPosition = SeekPosition(2300);

      expect(
        () => target.addTimingPoint(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "The seek position is out of the valid range.",
        )),
      );
    });

    test('Test to add a timing point twice. No.1', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("", const Duration(milliseconds: 50)),
        Word("fghijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(2360);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 60)),
        Word("", const Duration(milliseconds: 40)),
        Word("fghijk", const Duration(milliseconds: 700)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.1', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(4);
      final SeekPosition seekPosition = SeekPosition(5450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("d", const Duration(milliseconds: 50)),
        Word("e", const Duration(milliseconds: 250)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.2', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(18);
      final SeekPosition seekPosition = SeekPosition(7200);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("r", const Duration(milliseconds: 100)),
        Word("s", const Duration(milliseconds: 100)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.1', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(5450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 50)),
        Word("", const Duration(milliseconds: 250)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(5800);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("", const Duration(milliseconds: 100)),
        Word("fghijkl", const Duration(milliseconds: 600)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to throw TimingPointException when tring to add a timing point third time at the same insertion position. No.1', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      final SeekPosition seekPosition = SeekPosition(5800);

      expect(
        () => target.addTimingPoint(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "A timing point cannot be inserted three times or more at the same char position.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final option = Option.former;
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("defghijk", const Duration(milliseconds: 800)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });

    test('Test to delete a timing point. No.2', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(11);
      final option = Option.former;
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fghijklmno", const Duration(milliseconds: 1200)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });

    test('Test to try to delete a non-existent timing point.', () {
      Timeline target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(6);
      const option = Option.former;

      expect(
        () => target.deleteTiming(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      const option = Option.former;
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("defghijkl", const Duration(milliseconds: 1000)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });

    test('Test to delete a timing point. No.2', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(17);
      const option = Option.former;
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopqrs", const Duration(milliseconds: 800)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });

    test('Test to try to delete a non-existent timing point.', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(18);
      const option = Option.latter;

      expect(
        () => target.deleteTiming(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to a former timing point of a character position.', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      const option = Option.former;
      final WordList expected = WordList([
        Word("abc", Duration(milliseconds: 400)),
        Word("de", Duration(milliseconds: 300)),
        Word("fghijkl", Duration(milliseconds: 800)),
        Word("mnopq", Duration(milliseconds: 600)),
        Word("rs", Duration(milliseconds: 200)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });

    test('Test to a latter timing point of a character position.', () {
      Timeline target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      const option = Option.latter;
      final WordList expected = WordList([
        Word("abc", Duration(milliseconds: 400)),
        Word("de", Duration(milliseconds: 300)),
        Word("fghijkl", Duration(milliseconds: 700)),
        Word("mnopq", Duration(milliseconds: 700)),
        Word("rs", Duration(milliseconds: 200)),
      ]);

      target = target.deleteTiming(characterPosition, option);

      expect(target.wordList, expected);
    });
  });
}
