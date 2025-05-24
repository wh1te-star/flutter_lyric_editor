import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';
import 'package:lyric_editor/diff_function/backtract_table.dart';
import 'package:lyric_editor/diff_function/word_diff.dart';
import 'package:lyric_editor/diff_function/lcs_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';
import 'package:lyric_editor/position/word_range.dart';

class CharDiff {
  String beforeStr;
  String afterStr;
  late LongestCommonSequence _lcs;
  late BacktrackTable backtrackTable;

  CharDiff(this.beforeStr, this.afterStr) {
    _lcs = LongestCommonSequence(firstStr: beforeStr, secondStr: afterStr);
    backtrackTable = BacktrackTable(lcs: _lcs);
  }

  List<WordDiff> translateRouteToWordDiff(BacktrackRoute route) {
    final List<WordDiff> words = <WordDiff>[];
    final List<BacktrackPoint> points = route.points;

    if (points.isEmpty) {
      return [WordDiff(beforeStr, afterStr)];
    }

    BacktrackPoint start = points.first;
    BacktrackPoint previous = points.first;

    if (start.row != 0 || start.column != 0) {
      words.add(WordDiff(
        beforeStr.substring(0, start.row),
        afterStr.substring(0, start.column),
      ));
    }
    for (int i = 1; i < points.length; i++) {
      BacktrackPoint current = points[i];

      if (previous.row + 1 != current.row || previous.column + 1 != current.column) {
        words.add(WordDiff(
          beforeStr.substring(start.row, previous.row + 1),
          afterStr.substring(start.column, previous.column + 1),
        ));
        words.add(WordDiff(
          beforeStr.substring(previous.row + 1, current.row),
          afterStr.substring(previous.column + 1, current.column),
        ));
        start = current;
      }

      previous = current;
    }
    words.add(WordDiff(
      beforeStr.substring(start.row, previous.row + 1),
      afterStr.substring(start.column, previous.column + 1),
    ));
    if (previous.row + 1 != beforeStr.length || previous.column + 1 != afterStr.length) {
      words.add(WordDiff(
        beforeStr.substring(previous.row + 1),
        afterStr.substring(previous.column + 1),
      ));
    }
    return words;
  }

  List<WordDiff> getWordDiffs() {
    BacktrackRoute route = backtrackTable.getCommonIndex().last;
    return translateRouteToWordDiff(route);
  }

  List<WordDiff> getLeastWordDiffOne() {
    int INT_MAX = 9223372036854775807;
    List<WordDiff> minWordDiffRoute = [];
    int minWordDiffCount = INT_MAX;
    for (BacktrackRoute route in backtrackTable.getCommonIndex()) {
      List<WordDiff> wordDiffs = translateRouteToWordDiff(route);
      if (wordDiffs.length < minWordDiffCount) {
        minWordDiffRoute = wordDiffs;
        minWordDiffCount = wordDiffs.length;
      }
    }
    return minWordDiffRoute;
  }

  @override
  String toString() {
    return backtrackTable.toString();
  }
}
