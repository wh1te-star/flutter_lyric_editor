import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/diff_segment.dart';
import 'package:lyric_editor/diff_function/char_diff.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

void main() {
  group('Longest Common Subsequence test', () {
    setUp(() {});

    test('Normal string test', () {
      const String firstStr = "GAC";
      const String secondStr = "AGCAT";
      final LongestCommonSequence lcm = LongestCommonSequence(firstStr: firstStr, secondStr: secondStr);

      final List<List<LCMCell>> expected = [
        [
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
        ],
        [
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcmLength: 1),
        ],
        [
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcmLength: 2),
          LCMCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcmLength: 2),
        ],
        [
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcmLength: 0),
          LCMCell(fromLeft: false, fromUpper: true, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 1),
          LCMCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcmLength: 2),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 2),
          LCMCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcmLength: 2),
        ],
      ];

      List<List<LCMCell>> result = List.generate(
        firstStr.length + 1,
        (rowIndex) => List.generate(
          secondStr.length + 1,
          (colIndex) => lcm.cell(rowIndex, colIndex),
        ),
      );
      expect(result, equals(expected));
    });
  });
}
