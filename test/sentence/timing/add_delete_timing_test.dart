import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

void main() {
  group('Tests to add and delete a timing point.', () {
    final Timetable dataSet1 = Timetable(
      startTimestamp: AbsoluteSeekPosition(2000),
      wordList: WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fghijk", const Duration(milliseconds: 700)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]),
    );
    final Timetable dataSet2 = Timetable(
      startTimestamp: AbsoluteSeekPosition(5000),
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
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(7);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fg", const Duration(milliseconds: 50)),
        Word("hijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point No.2', () {
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(8);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("fgh", const Duration(milliseconds: 50)),
        Word("ijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test the seek position is not valid', () {
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(8);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(2300);

      expect(
        () => target.addTiming(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "The seek position is out of the valid range.",
        )),
      );
    });

    test('Test to add a timing point twice. No.1', () {
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(2450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 100)),
        Word("", const Duration(milliseconds: 50)),
        Word("fghijk", const Duration(milliseconds: 650)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(2360);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 300)),
        Word("de", const Duration(milliseconds: 60)),
        Word("", const Duration(milliseconds: 40)),
        Word("fghijk", const Duration(milliseconds: 700)),
        Word("lmno", const Duration(milliseconds: 500)),
        Word("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point to a sentence that have a char position with 2 timing point. No.1', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(4);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(5450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("d", const Duration(milliseconds: 50)),
        Word("e", const Duration(milliseconds: 250)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point to a sentence that have a char position with 2 timing point. No.2', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(18);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(7200);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("r", const Duration(milliseconds: 100)),
        Word("s", const Duration(milliseconds: 100)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.1', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(5450);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 50)),
        Word("", const Duration(milliseconds: 250)),
        Word("fghijkl", const Duration(milliseconds: 700)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(5800);
      final WordList expected = WordList([
        Word("abc", const Duration(milliseconds: 400)),
        Word("de", const Duration(milliseconds: 300)),
        Word("", const Duration(milliseconds: 100)),
        Word("fghijkl", const Duration(milliseconds: 600)),
        Word("", const Duration(milliseconds: 100)),
        Word("mnopq", const Duration(milliseconds: 600)),
        Word("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTiming(characterPosition, seekPosition);

      expect(target.wordList, expected);
    });

    test('Test to throw TimingException when tring to add a timing point third time at the same caret position. No.1', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(12);
      final AbsoluteSeekPosition seekPosition = AbsoluteSeekPosition(5800);

      expect(
        () => target.addTiming(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "A timing point cannot be inserted three times or more at the same char position.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
      final Option option = Option.former;
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
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(11);
      final Option option = Option.former;
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
      Timetable target = dataSet1.copyWith();
      final CaretPosition characterPosition = CaretPosition(6);
      const option = Option.former;

      expect(
        () => target.deleteTiming(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(5);
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
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(17);
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
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(18);
      const option = Option.latter;

      expect(
        () => target.deleteTiming(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to a former timing point of a character position.', () {
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(12);
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
      Timetable target = dataSet2.copyWith();
      final CaretPosition characterPosition = CaretPosition(12);
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
