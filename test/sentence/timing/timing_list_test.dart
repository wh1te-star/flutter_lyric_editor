import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/lyric_data/timing/timing_list.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

void main() {
  group('test', () {
    setUp(() {});

    test('Test there is the possibility to make an invalid list if the list class don\'t assert each items while each item itself have the assertion.', skip: true, () {
      expect(() => Timing(CaretPosition(-1), SeekPosition(0)), throwsAssertionError);

      TimingList list = TimingList([
        Timing(CaretPosition(-1), SeekPosition(0)),
      ]);

      expect(list.list.first.caretPosition, -1);

      expect(() => Timing(CaretPosition(-1), SeekPosition(0)), throwsAssertionError);
    });
  });
}
