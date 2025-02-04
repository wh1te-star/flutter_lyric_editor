import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';

void main() {
  group('Backtrack of Longest Common Subsequence Test', () {
      BacktrackRoute defaultRoute = BacktrackRoute([
        BacktrackPoint(-1, -1),
        BacktrackPoint(1, 1),
      ]);
      BacktrackRoute anotherRoute = BacktrackRoute([
        BacktrackPoint(-1, -1),
        BacktrackPoint(2, 2),
      ]);
    setUp(() {});

    test('Route Inherit Test for a Duplicated Route', () {
      BacktrackCell previousCell = BacktrackCell([defaultRoute]);
      BacktrackCell result = previousCell.inheritRoutes(BacktrackCell([defaultRoute]));
      BacktrackCell expected = BacktrackCell([defaultRoute]);

      expect(result, equals(expected));
    });

    test('Route Inherit Test for a New Route', () {
      BacktrackCell previousCell = BacktrackCell([defaultRoute]);
      BacktrackCell result = previousCell.inheritRoutes(BacktrackCell([anotherRoute]));
      BacktrackCell expected = BacktrackCell([defaultRoute, anotherRoute]);

      expect(result, equals(expected));
    });
  });
}
