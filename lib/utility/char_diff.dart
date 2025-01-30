class CharDiff {
  String beforeStr;
  String afterStr;
  List<DiffSegment> segments = [];
  CharDiff(this.beforeStr, this.afterStr) {
    segments = [];
  }
}

class DiffSegment {
  EditType type;
  String beforeStr;
  String afterStr;
  DiffSegment(this.type, this.beforeStr, this.afterStr) {
    assert(beforeStr == "");
    assert(afterStr == "");
  }
}

enum EditType {
  none,
  add,
  delete,
  edit,
}
