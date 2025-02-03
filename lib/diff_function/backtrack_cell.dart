import 'package:lyric_editor/diff_function/longest_common_subsequence.dart';

class BacktrackTree {
  BacktrackNode treeNodes;
  LongestCommonSequence lcm;
  List<BacktrackNode> route = [];

  BacktrackTree({required this.lcm, required this.root}) {
    constructTree();
  }

  void constructTree() {
    lcm.cell(0, 0);
  }
}

class BacktrackNode {
  int first;
  int second;
  BacktrackNode leftNode = BacktrackNode(first: -1, second: -1);
  BacktrackNode rightNode = BacktrackNode(first: -1, second: -1);

  BacktrackNode({
    required this.first,
    required this.second,
  }) {
    if (first != -1 || second != -1) {
      assert(first >= 0);
      assert(second >= 0);
    }
  }

  static BacktrackNode emptyNode() {
    return BacktrackNode(first: -1, second: -1);
  }
}
