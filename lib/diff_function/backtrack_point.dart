class BacktrackPoint {
  int row;
  int column;

  BacktrackPoint(this.row, this.column) {
    if (row != -1 || column != -1) {
      assert(row >= 0);
      assert(column >= 0);
    }
  }

  static BacktrackPoint dummyPoint() => BacktrackPoint(-1, -1);

  @override
  String toString() {
    return "($row, $column)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BacktrackPoint) return false;
    return row == other.row && column == other.column;
  }

  @override
  int get hashCode => row.hashCode ^ column.hashCode;
}