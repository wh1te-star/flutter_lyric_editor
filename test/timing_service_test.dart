import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'timing_service_test.mocks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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

    test('Test the normal inserts 1', () {
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

    test('Test the normal inserts 2', () {
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
    test('addTimingPoint should throw TimingPointException when index != seekIndex', () {
      final LyricSnippet targetSnippet = dataSetSnippet1.copyWith();
      final characterPosition = 8;
      final seekPosition = 2300;

      expect(() => timingService.addTimingPoint(targetSnippet, characterPosition, seekPosition), throwsA(isA<TimingPointException>()));
    });
  });
}
