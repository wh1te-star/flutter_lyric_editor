class BacktrackStep {
  int first;
  int second;

  BacktrackStep({
    required this.first,
    required this.second,
  }) {
    assert(first >= 0);
    assert(second >= 0);
  }
}
