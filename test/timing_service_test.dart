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
      timingPoints: [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(6, 700),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ],
    );
    final dataSetSnippet2 = LyricSnippet(
      vocalist: Vocalist("sample vocalist name", Colors.black.value),
      index: 0,
      sentence: "abcdefghijklmnopqrs",
      startTimestamp: 5000,
      timingPoints: [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
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
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 300),
        TimingPoint(1, 50),
        TimingPoint(1, 50),
        TimingPoint(6, 700),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point to a snippet No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 8;
      final seekPosition = 2450;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(3, 50),
        TimingPoint(3, 650),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test the seek position is not valid range.', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 8;
      final seekPosition = 2300;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("valid range"));
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 5;
      final seekPosition = 2450;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 300),
        TimingPoint(2, 100),
        TimingPoint(0, 50),
        TimingPoint(6, 650),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 5;
      final seekPosition = 2360;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 300),
        TimingPoint(2, 60),
        TimingPoint(0, 40),
        TimingPoint(6, 700),
        TimingPoint(4, 500),
        TimingPoint(5, 600),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 4;
      final seekPosition = 5450;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 400),
        TimingPoint(1, 50),
        TimingPoint(1, 250),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point to a snippet that have a char position with 2 timing point. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 18;
      final seekPosition = 7200;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(1, 100),
        TimingPoint(1, 100),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point twice. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 5;
      final seekPosition = 5450;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 400),
        TimingPoint(2, 50),
        TimingPoint(0, 250),
        TimingPoint(7, 700),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to add a timing point twice. No.2', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 5;
      final seekPosition = 5800;
      final List<TimingPoint> expectedTimingPoints = [
        TimingPoint(3, 400),
        TimingPoint(2, 300),
        TimingPoint(0, 100),
        TimingPoint(7, 600),
        TimingPoint(0, 100),
        TimingPoint(5, 600),
        TimingPoint(2, 200),
      ];

      timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition);

      expect(targetSnippet.timingPoints, expectedTimingPoints);
    });

    test('Test to throw TimingPointException when tring to add a timing point third time at the same char position. No.1', () {
      final LyricSnippet targetSnippet = dataSetSnippet2.copyWith();
      final characterPosition = 12;
      final seekPosition = 5800;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsExceptionWithMessageContaining("Cannot add timing point more than 2"));
    });
  });
}
