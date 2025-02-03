import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

class BacktrackTable {
  LongestCommonSequence lcm;
  List<BacktrackCell> routes = [];

  BacktrackTable({required this.lcm}) {
    establishRoute();
  }

  void establishRoute() {
  }
}

class BacktrackCell {
  List<BacktrackPoint> routes=[];
}

class BacktrackPoint {
  int row;
  int column;

  BacktrackPoint(this.row, this.column) {
    assert(row >= 0);
    assert(column >= 0);
  }
}
