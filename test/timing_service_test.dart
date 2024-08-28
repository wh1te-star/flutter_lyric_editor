import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:xml/xml_events.dart';
import 'timing_service_test.mocks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

Matcher throwsExceptionWithMessageContaining(String substring) {
  return throwsA(predicate((e) => e is TimingPointException && e.message.contains(substring)));
}

void main() {
  group('Timing point test.', () {
    late MockBuildContext mockContext;
    late PublishSubject<dynamic> masterSubject;
    late TimingService timingService;
    final dataSetSnippet1 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghijklmnopqrst",
      startTimestamp: 2000,
      sentenceSegments: [
        SentenceSegment(3, 300),
        SentenceSegment(2, 100),
        SentenceSegment(6, 700),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ],
    );
    final dataSetSnippet2 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghijklmnopqrs",
      startTimestamp: 5000,
      sentenceSegments: [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ],
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      mockContext = MockBuildContext();
      masterSubject = PublishSubject<dynamic>();
      timingService = TimingService(masterSubject: masterSubject, context: mockContext);
    });

    test('Test to add a timing point to a snippet No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final int characterPosition = 7;
      final int seekPosition = 2450;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(2, 100),
        SentenceSegment(2, 50),
        SentenceSegment(4, 650),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point to a snippet No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 8;
      final seekPosition = 2450;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(2, 100),
        SentenceSegment(3, 50),
        SentenceSegment(3, 650),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test the seek position is not valid', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 8;
      final seekPosition = 2300;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("not valid"));
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 5;
      final seekPosition = 2450;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(2, 100),
        SentenceSegment(0, 50),
        SentenceSegment(6, 650),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 5;
      final seekPosition = 2360;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(2, 60),
        SentenceSegment(0, 40),
        SentenceSegment(6, 700),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 4;
      final seekPosition = 5450;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(1, 50),
        SentenceSegment(1, 250),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 18;
      final seekPosition = 7200;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(1, 100),
        SentenceSegment(1, 100),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 5;
      final seekPosition = 5450;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 50),
        SentenceSegment(0, 250),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 5;
      final seekPosition = 5800;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(0, 100),
        SentenceSegment(7, 600),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to throw TimingPointException when tring to add a timing point third time at the same char position. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 12;
      final seekPosition = 5800;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("Cannot add timing point more than 2"));
    });

    test('Test to delete a timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 5;
      final option = Option.former;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(8, 800),
        SentenceSegment(4, 500),
        SentenceSegment(5, 600),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 11;
      final option = Option.former;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(2, 100),
        SentenceSegment(10, 1200),
        SentenceSegment(5, 600),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to try to delete a non-existent timing point.', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 6;
      final option = Option.former;

      expect(() => timingService.deleteTimingPoint(targetSnippet, characterPosition, option), throwsExceptionWithMessageContaining("There is not specified timing point."));
    });

    test('Test to delete a timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 5;
      final option = Option.former;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(9, 1000),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 17;
      final option = Option.former;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(7, 800),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to try to delete a non-existent timing point.', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 17;
      final option = Option.latter;

      expect(() => timingService.deleteTimingPoint(targetSnippet, characterPosition, option), throwsExceptionWithMessageContaining("There is not specified timing point."));
    });

    test('Test to a former timing point of a character position.', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 12;
      final option = Option.former;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 800),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to a latter timing point of a character position.', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 12;
      final option = Option.latter;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 700),
        SentenceSegment(5, 700),
        SentenceSegment(2, 200),
      ];

      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
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
        SentenceSegment(1, 200),
        SentenceSegment(3, 400),
        SentenceSegment(4, 500),
        SentenceSegment(2, 300),
      ],
    );
    final dataSetSnippet2 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghijklmnopqrs",
      startTimestamp: 5000,
      sentenceSegments: [
        SentenceSegment(3, 400),
        SentenceSegment(2, 300),
        SentenceSegment(7, 700),
        SentenceSegment(0, 100),
        SentenceSegment(5, 600),
        SentenceSegment(2, 200),
      ],
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      mockContext = MockBuildContext();
      masterSubject = PublishSubject<dynamic>();
      timingService = TimingService(masterSubject: masterSubject, context: mockContext);
    });

    test('Test the index translation when deleting a word.', () {
      final String oldSentence = "abcde";
      final String newSentence = "abce";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 3, 4];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when adding a word.', () {
      final String oldSentence = "abcde";
      final String newSentence = "abcdxxe";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 4, 7];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when editting a word. No.1', () {
      final String oldSentence = "abcde";
      final String newSentence = "abcxxe";
      final List<int> expectedIndexTranslation = [0, 1, 2, 3, 5, 6];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test the index translation when editting a word. No.2', () {
      final String oldSentence = "abcde";
      final String newSentence = "axyzwze";
      final List<int> expectedIndexTranslation = [0, 1, -1, -1, 6, 7];

      final List<int> resultIndexTranslation = timingService.getCharPositionTranslation(oldSentence, newSentence);

      expect(resultIndexTranslation, expectedIndexTranslation);
    });

    test('Test to edit a substring from a sentence.', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final String newSentence = "abcxxxhij";
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(1, 200),
        SentenceSegment(6, 900),
        SentenceSegment(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to delete a substring from a sentence.', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final String newSentence = "abchij";
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(1, 200),
        SentenceSegment(3, 900),
        SentenceSegment(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test to add a string to a sentence.', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final String newSentence = "abcdefgxxhij";
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(1, 200),
        SentenceSegment(3, 400),
        SentenceSegment(6, 500),
        SentenceSegment(2, 300),
      ];

      timingService.editSentence(targetSnippet, newSentence);

      expect(targetSnippet.sentence, newSentence);
      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);
    });

    test('Test the seek position is not valid', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final String newSentence = "abcdefghijklmnopqrst";

      /*
      timingService.deleteTimingPoint(targetSnippet, characterPosition, option);

      expect(targetSnippet.sentenceSegments, expectedSentenceSegments);

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("not valid"));
      */
    });
  });
}
