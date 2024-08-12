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

    setUp(() {
      mockContext = MockBuildContext();
      masterSubject = PublishSubject<dynamic>();
      timingService = TimingService(masterSubject: masterSubject, context: mockContext);
    });

    test('addTimingPoint should add a new timing point to the snippet', () {
      // Arrange
      final snippet = LyricSnippet(
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
      final characterPosition = 4;
      final seekPosition = 2350;

      final expectedSnippet = LyricSnippet(
        vocalist: Vocalist("sample vocalist name", Colors.black.value),
        index: 0,
        sentence: "abcdefghijklmnopqrst",
        startTimestamp: 2000,
        timingPoints: [
          TimingPoint(3, 300),
          TimingPoint(1, 50),
          TimingPoint(1, 50),
          TimingPoint(6, 700),
          TimingPoint(4, 500),
          TimingPoint(5, 600),
        ],
      );

      timingService.addTimingPoint(snippet, characterPosition, seekPosition);

      snippet.timingPoints.forEach((TimingPoint timingPoint) {
        debugPrint("${timingPoint.wordLength}, ${timingPoint.wordDuration}");
      });
      expect(snippet, expectedSnippet);
    });
  });
}
