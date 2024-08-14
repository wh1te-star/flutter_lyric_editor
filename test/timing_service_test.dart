import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'timing_service_test.mocks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

Matcher throwsExceptionWithMessageContaining(String substring) {
  return throwsA(predicate((e) => e is TimingPointException && e.message.contains(substring)));
}

void main() {
  group('TimingService', () {
    TestWidgetsFlutterBinding.ensureInitialized();

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

    setUp(() {
      mockContext = MockBuildContext();
      masterSubject = PublishSubject<dynamic>();
      timingService = TimingService(masterSubject: masterSubject, context: mockContext);
    });

    test('Test to add a timing point to a snippet No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final int characterPosition = 4;
      final int seekPosition = 2350;
      final List<SentenceSegment> expectedSentenceSegments = [
        SentenceSegment(3, 300),
        SentenceSegment(1, 50),
        SentenceSegment(1, 50),
        SentenceSegment(6, 700),
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
  });
}
