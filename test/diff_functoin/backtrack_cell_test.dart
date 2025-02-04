import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/lcm_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

void main() {
  group('Backtrack of Longest Common Subsequence Test', () {
    setUp(() {});

    test('Normal string test', () {
      const String firstStr = "GAC";
      const String secondStr = "AGCAT";
      final LongestCommonSequence lcm = LongestCommonSequence(firstStr: firstStr, secondStr: secondStr);
      final BacktrackTable backtrackTable = BacktrackTable(lcm: lcm);

      List<BacktrackRoute> result = backtrackTable.getCommonIndex();

      final List<BacktrackRoute> candidate = [
        BacktrackRoute([
          BacktrackPoint(0, 1),
          BacktrackPoint(1, 3),
        ]),
        BacktrackRoute([
          BacktrackPoint(0, 1),
          BacktrackPoint(2, 2),
        ]),
        BacktrackRoute([
          BacktrackPoint(1, 0),
          BacktrackPoint(2, 2),
        ]),
      ];

      //expect(result.length, equals(candidate.length));
      expect(result, unorderedEquals(candidate));
    });
  });
}
