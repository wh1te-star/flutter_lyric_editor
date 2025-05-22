import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

void main() {
  group('test', () {
    setUp(() {});

    test('Test there is the possibility to make an invalid list if the list class don\'t assert each items while each item itself have the assertion.', skip: true, () {
      expect(() => TimingPoint(InsertionPosition(-1), SeekPosition(0)), throwsAssertionError);

      TimingList list = TimingList([
        TimingPoint(InsertionPosition(-1), SeekPosition(0)),
      ]);

      expect(list.list.first.insertionPosition, -1);

      expect(() => TimingPoint(InsertionPosition(-1), SeekPosition(0)), throwsAssertionError);
    });
  });
}
