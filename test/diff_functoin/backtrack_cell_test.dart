import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/old/diff_function/backtrack_cell.dart';
import 'package:lyric_editor/old/diff_function/backtrack_point.dart';
import 'package:lyric_editor/old/diff_function/backtrack_route.dart';

void main() {
  group('Backtrack of Longest Common Subsequence Test', () {
    BacktrackRoute defaultRoute = BacktrackRoute.dummyRoute();
    BacktrackRoute anotherRoute = BacktrackRoute.dummyRoute();
    BacktrackRoute pointAddingRoute = BacktrackRoute.dummyRoute();

    setUp(() {
      defaultRoute = BacktrackRoute([
        BacktrackPoint(-1, -1),
        BacktrackPoint(1, 1),
      ]);
      anotherRoute = BacktrackRoute([
        BacktrackPoint(-1, -1),
        BacktrackPoint(2, 2),
      ]);
      pointAddingRoute = BacktrackRoute([
        BacktrackPoint(-1, -1),
        BacktrackPoint(1, 1),
        BacktrackPoint(2, 2),
      ]);
    });

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

    test('Point Adding Test', () {
      BacktrackCell previousCell = BacktrackCell([defaultRoute]);
      BacktrackCell result = previousCell.addNewPoint(2, 2);
      BacktrackCell expected = BacktrackCell([
        BacktrackRoute([
          BacktrackPoint(-1, -1),
          BacktrackPoint(1, 1),
          BacktrackPoint(2, 2),
        ]),
      ]);

      expect(result, equals(expected));
    });

    test('Point Adding Test for multiple existing routes', () {
      BacktrackCell previousCell = BacktrackCell([defaultRoute, anotherRoute]);
      BacktrackCell result = previousCell.addNewPoint(3, 3);
      BacktrackCell expected = BacktrackCell([
        BacktrackRoute([
          BacktrackPoint(-1, -1),
          BacktrackPoint(1, 1),
          BacktrackPoint(3, 3),
        ]),
        BacktrackRoute([
          BacktrackPoint(-1, -1),
          BacktrackPoint(2, 2),
          BacktrackPoint(3, 3),
        ]),
      ]);

      expect(result, equals(expected));
    });
  });
}
