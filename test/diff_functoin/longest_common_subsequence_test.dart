import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/lcs_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

void main() {
  group('Longest Common Subsequence Test', () {
    setUp(() {});

    test('Normal string test', () {
      const String firstStr = "GAC";
      const String secondStr = "AGCAT";
      final LongestCommonSequence lcs = LongestCommonSequence(firstStr: firstStr, secondStr: secondStr);

      final List<List<LCSCell>> expected = [
        [
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
        ],
        [
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcsLength: 1),
        ],
        [
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcsLength: 2),
          LCSCell(fromLeft: true, fromUpper: false, fromLeftUpper: false, lcsLength: 2),
        ],
        [
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: false, lcsLength: 0),
          LCSCell(fromLeft: false, fromUpper: true, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 1),
          LCSCell(fromLeft: false, fromUpper: false, fromLeftUpper: true, lcsLength: 2),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 2),
          LCSCell(fromLeft: true, fromUpper: true, fromLeftUpper: false, lcsLength: 2),
        ],
      ];

      List<List<LCSCell>> result = List.generate(
        firstStr.length + 1,
        (rowIndex) => List.generate(
          secondStr.length + 1,
          (colIndex) => lcs.cell(rowIndex, colIndex),
        ),
      );
      expect(result, equals(expected));
    });
  });
}
