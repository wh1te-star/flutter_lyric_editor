import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';

void main() {
  group('Tests to add and delete a timing point.', () {
    final Timing dataSet1 = Timing(
      startTimestamp: SeekPosition(2000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 100)),
        SentenceSegment("fghijk", const Duration(milliseconds: 700)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]),
    );
    final Timing dataSet2 = Timing(
      startTimestamp: SeekPosition(5000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]),
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {});

    test('Test to add a timing point No.1', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(7);
      final SeekPosition seekPosition = SeekPosition(2450);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 100)),
        SentenceSegment("fg", const Duration(milliseconds: 50)),
        SentenceSegment("hijk", const Duration(milliseconds: 650)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point No.2', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(8);
      final SeekPosition seekPosition = SeekPosition(2450);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 100)),
        SentenceSegment("fgh", const Duration(milliseconds: 50)),
        SentenceSegment("ijk", const Duration(milliseconds: 650)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test the seek position is not valid', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(8);
      final SeekPosition seekPosition = SeekPosition(2300);

      expect(
        () => target.addTimingPoint(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingPointException && e.message == "The seek position is out of the valid range.",
        )),
      );
    });

    test('Test to add a timing point twice. No.1', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(2450);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 100)),
        SentenceSegment("", const Duration(milliseconds: 50)),
        SentenceSegment("fghijk", const Duration(milliseconds: 650)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(2360);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 60)),
        SentenceSegment("", const Duration(milliseconds: 40)),
        SentenceSegment("fghijk", const Duration(milliseconds: 700)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.1', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(4);
      final SeekPosition seekPosition = SeekPosition(5450);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("d", const Duration(milliseconds: 50)),
        SentenceSegment("e", const Duration(milliseconds: 250)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.2', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(18);
      final SeekPosition seekPosition = SeekPosition(7200);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("r", const Duration(milliseconds: 100)),
        SentenceSegment("s", const Duration(milliseconds: 100)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point twice. No.1', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(5450);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 50)),
        SentenceSegment("", const Duration(milliseconds: 250)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to add a timing point twice. No.2', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final SeekPosition seekPosition = SeekPosition(5800);
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 300)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 600)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.addTimingPoint(characterPosition, seekPosition);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to throw TimingPointException when tring to add a timing point third time at the same insertion position. No.1', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      final SeekPosition seekPosition = SeekPosition(5800);

      expect(
        () => target.addTimingPoint(characterPosition, seekPosition),
        throwsA(predicate(
          (e) => e is TimingPointException && e.message == "A timing point cannot be inserted three times or more at the same char position.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      final option = Option.former;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("defghijk", const Duration(milliseconds: 800)),
        SentenceSegment("lmno", const Duration(milliseconds: 500)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to delete a timing point. No.2', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(11);
      final option = Option.former;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 300)),
        SentenceSegment("de", const Duration(milliseconds: 100)),
        SentenceSegment("fghijklmno", const Duration(milliseconds: 1200)),
        SentenceSegment("pqrst", const Duration(milliseconds: 600)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to try to delete a non-existent timing point.', () {
      Timing target = dataSet1.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(6);
      const option = Option.former;

      expect(
        () => target.deleteTimingPoint(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingPointException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to delete a timing point. No.1', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(5);
      const option = Option.former;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("defghijkl", const Duration(milliseconds: 1000)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopq", const Duration(milliseconds: 600)),
        SentenceSegment("rs", const Duration(milliseconds: 200)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to delete a timing point. No.2', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(17);
      const option = Option.former;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", const Duration(milliseconds: 400)),
        SentenceSegment("de", const Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", const Duration(milliseconds: 700)),
        SentenceSegment("", const Duration(milliseconds: 100)),
        SentenceSegment("mnopqrs", const Duration(milliseconds: 800)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to try to delete a non-existent timing point.', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(18);
      const option = Option.latter;

      expect(
        () => target.deleteTimingPoint(characterPosition, option),
        throwsA(predicate(
          (e) => e is TimingPointException && e.message == "There is not the specified timing point.",
        )),
      );
    });

    test('Test to a former timing point of a character position.', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      const option = Option.former;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", Duration(milliseconds: 400)),
        SentenceSegment("de", Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", Duration(milliseconds: 800)),
        SentenceSegment("mnopq", Duration(milliseconds: 600)),
        SentenceSegment("rs", Duration(milliseconds: 200)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });

    test('Test to a latter timing point of a character position.', () {
      Timing target = dataSet2.copyWith();
      final InsertionPosition characterPosition = InsertionPosition(12);
      const option = Option.latter;
      final SentenceSegmentList expected = SentenceSegmentList([
        SentenceSegment("abc", Duration(milliseconds: 400)),
        SentenceSegment("de", Duration(milliseconds: 300)),
        SentenceSegment("fghijkl", Duration(milliseconds: 700)),
        SentenceSegment("mnopq", Duration(milliseconds: 700)),
        SentenceSegment("rs", Duration(milliseconds: 200)),
      ]);

      target = target.deleteTimingPoint(characterPosition, option);

      expect(target.sentenceSegmentList, expected);
    });
  });
}
