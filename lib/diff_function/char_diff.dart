import 'package:lyric_editor/diff_function/backtrack_point.dart';
import 'package:lyric_editor/diff_function/backtrack_route.dart';
import 'package:lyric_editor/diff_function/backtract_table.dart';
import 'package:lyric_editor/diff_function/diff_segment.dart';
import 'package:lyric_editor/diff_function/lcs_cell.dart';
import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';

class CharDiff {
  String beforeStr;
  String afterStr;
  late LongestCommonSequence _lcs;
  late BacktrackTable backtrackTable;

  CharDiff(this.beforeStr, this.afterStr) {
    _lcs = LongestCommonSequence(firstStr: beforeStr, secondStr: afterStr);
    backtrackTable = BacktrackTable(lcs: _lcs);
  }

  List<DiffSegment> translateRouteToSegment(BacktrackRoute route) {
    final List<DiffSegment> segments = <DiffSegment>[];
    final List<BacktrackPoint> points = route.points;

    if (points.isEmpty) {
      return [DiffSegment(beforeStr, afterStr)];
    }

    BacktrackPoint start = points.first;
    BacktrackPoint previous = points.first;
    for (int i = 1; i < points.length; i++) {
      BacktrackPoint current = points[i];

      if (previous.row + 1 != current.row || previous.column + 1 != current.column) {
        segments.add(DiffSegment(
          beforeStr.substring(start.row, previous.row + 1),
          afterStr.substring(start.column, previous.column + 1),
        ));
        segments.add(DiffSegment(
          beforeStr.substring(previous.row + 1, current.row),
          afterStr.substring(previous.column + 1, current.column),
        ));
        start = current;
      }

      previous = current;
    }
    segments.add(DiffSegment(
      beforeStr.substring(start.row),
      afterStr.substring(start.column),
    ));
    return segments;
  }

  List<DiffSegment> getDiffSegments() {
    BacktrackRoute route = backtrackTable.getCommonIndex().last;
    return translateRouteToSegment(route);
  }

  List<DiffSegment> getLeastSegmentOne() {
    int INT_MAX = 9223372036854775807;
    List<DiffSegment> minSegmentRoute = [];
    int minSegmentCount = INT_MAX;
    for (BacktrackRoute route in backtrackTable.getCommonIndex()) {
      List<DiffSegment> segments = translateRouteToSegment(route);
      if (segments.length < minSegmentCount) {
        minSegmentRoute = segments;
        minSegmentCount = segments.length;
      }
    }
    return minSegmentRoute;
  }

  @override
  String toString() {
    return backtrackTable.toString();
  }
}
