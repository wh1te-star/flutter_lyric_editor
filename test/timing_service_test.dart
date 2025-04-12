import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
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

    /*
    test('Test to add a timing point to a snippet No.2', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 8;
      const seekPosition = 2450;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(3, 50),
        TimingPoint(3, 650),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test the seek position is not valid', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 8;
      const seekPosition = 2300;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("not valid"));
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 5;
      const seekPosition = 2450;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(0, 50),
        TimingPoint(6, 650),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 5;
      const seekPosition = 2360;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 300),
        TimingPoint(2, 60),
        TimingPoint(0, 40),
        TimingPoint(6, 700),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 4;
      const seekPosition = 5450;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(1, 50),
        TimingPoint(1, 250),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 18;
      const seekPosition = 7200;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(1, 100),
        TimingPoint(1, 100),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 5;
      const seekPosition = 5450;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 50),
        TimingPoint(0, 250),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 5;
      const seekPosition = 5800;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(7, 600),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to throw TimingPointException when tring to add a timing point third time at the same char position. No.1', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 12;
      const seekPosition = 5800;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("Cannot add timing point more than 2"));
    });

    test('Test to delete a timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 5;
      const option = Option.former;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 300),
        TimingPoint(8, 800),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 11;
      const option = Option.former;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(10, 1200),
        TimingPoint(5, 600),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to try to delete a non-existent timing point.', () {
      final LyricSnippet targetSnippet = dataSet1.copyWith();
      const characterPosition = 6;
      const option = Option.former;

      expect(() => timingService.deleteTimingPoint(targetSnippet, characterPosition, option), throwsExceptionWithMessageContaining("There is not specified timing point."));
    });

    test('Test to delete a timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 5;
      const option = Option.former;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(9, 1000),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 17;
      const option = Option.former;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(7, 800),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to try to delete a non-existent timing point.', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 17;
      const option = Option.latter;

      expect(() => timingService.deleteTimingPoint(targetSnippet, characterPosition, option), throwsExceptionWithMessageContaining("There is not specified timing point."));
    });

    test('Test to a former timing point of a character position.', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 12;
      const option = Option.former;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 800),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });

    test('Test to a latter timing point of a character position.', () {
      final LyricSnippet targetSnippet = dataSet2.copyWith();
      const characterPosition = 12;
      const option = Option.latter;
      final List<TimingPoint> expectedSentenceSegments = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 700),
        TimingPoint(5, 700),
        TimingPoint(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet._sentenceSegments, expectedSentenceSegments);
    });
  });

  group('Edit sentence test.', () {
    late MockBuildContext mockContext;
    late PublishSubject<dynamic> masterSubject;
    late TimingService timingService;
    final dataSetSnippet1 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghij",
      startTimestamp: 2000,
      sentenceSegments: [
        TimingPoint(1, 200),
        TimingPoint(3, 400),
        TimingPoint(4, 500),
        TimingPoint(2, 300),
      ],
    );
    final dataSetSnippet2 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghijkl",
      startTimestamp: 5000,
      sentenceSegments: [
        TimingPoint(3, 400),
        TimingPoint(1, 300),
        TimingPoint(0, 100),
        TimingPoint(3, 500),
        TimingPoint(1, 100),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(2, 200),
      ],
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      mockContext = MockBuildContext();
      masterSubject = PublishSubject<dynamic>();
      timingService = TimingService(masterSubject: masterSubject, context: mockContext);
    });

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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
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
  */
  });
}
