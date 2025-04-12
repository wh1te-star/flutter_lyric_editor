import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_snippet/timing_point_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'timing_service_test.mocks.dart';

void main() {
  group('Timing point test.', () {
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
        throwsA(TimingPointException("The seek position is out of the valid range.")),
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

      expect(() => target.addTimingPoint(characterPosition, seekPosition), TimingPointException("Cannot add timing point more than 2"));
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

      expect(() => target.deleteTimingPoint(characterPosition, option), TimingPointException("There is not specified timing point."));
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
      final InsertionPosition characterPosition = InsertionPosition(17);
      const option = Option.latter;

      expect(() => target.deleteTimingPoint(characterPosition, option), TimingPointException("There is not specified timing point."));
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

  /*
  group('Edit sentence test.', () {
    final Timing dataSet1 = Timing(
      startTimestamp: SeekPosition(2000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("a", Duration(milliseconds: 200)),
        SentenceSegment("bcd", Duration(milliseconds: 400)),
        SentenceSegment("efgh", Duration(milliseconds: 500)),
        SentenceSegment("ij", Duration(milliseconds: 300)),
      ]),
    );
    final Timing dataSet2 = Timing(
      startTimestamp: SeekPosition(5000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("abc", Duration(milliseconds: 400)),
        SentenceSegment("d", Duration(milliseconds: 300)),
        SentenceSegment("", Duration(milliseconds: 100)),
        SentenceSegment("efg", Duration(milliseconds: 500)),
        SentenceSegment("h", Duration(milliseconds: 100)),
        SentenceSegment("ij", Duration(milliseconds: 300)),
        SentenceSegment("", Duration(milliseconds: 100)),
        SentenceSegment("kl", Duration(milliseconds: 200)),
      ]),
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {});

    test('Test the index translation when deleting a word.', () {
      const String oldSentence = "abcde";
      const String newSentence = "abce";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 3, 4];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when adding a word.', () {
      const String oldSentence = "abcde";
      const String newSentence = "abcdxxe";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 4, 7];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when editting a word. No.1', () {
      const String oldSentence = "abcde";
      const String newSentence = "abcxxe";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 5, 6];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when editting a word. No.2', () {
      const String oldSentence = "abcde";
      const String newSentence = "axyzwze";
      final List<int> expectedIndexTranslation = [0, 1, -1, -1, 6, 7];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test to edit a substring from a sentence. No.1', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abcxxxhij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(6, 900),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence. No.1', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abchij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(3, 900),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a string to a sentence. No.1', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abcdefgxxhij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(3, 400),
        TimingPoint(6, 500),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to edit a substring from a sentence. No.2 (Edit just a segment)', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abcdxxxij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(3, 400),
        TimingPoint(3, 500),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence. No.2 (Delete just a segment)', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abcdij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(3, 400),
        TimingPoint(0, 500),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a string to a sentence. No.2 (Add a string at the same position of a timing point)', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const String newSentence = "abcdxxefghij";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(1, 200),
        TimingPoint(3, 400),
        TimingPoint(6, 500),
        TimingPoint(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to edit a substring from a sentence. No.3', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abxxxghijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(6, 1300),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence. No.3', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abghijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 1300),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a string from a sentence. No.3', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abcdxxxefghijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(1, 300),
        TimingPoint(0, 100),
        TimingPoint(6, 500),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to edit a substring from a sentence. No.4 (Edit just a segment)', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abcdxxhijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(1, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 500),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence. No.4 (Delete just a segment)', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abcdhijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(1, 300),
        TimingPoint(0, 600),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence. No.5 (Delete just some segment)', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      const String newSentence = "abcdijkl";
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(1, 300),
        TimingPoint(0, 700),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test the seek position is not valid', () {
      const String newSentence = "abcdefghijklmnopqrst";

      /*
      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("not valid"));
      */
    });
  });
*/
}
