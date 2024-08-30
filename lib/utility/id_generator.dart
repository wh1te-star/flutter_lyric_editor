class SnippetID {
  int id;
  SnippetID(this.id);

  @override
  bool operator ==(Object other) {
    if (other is SnippetID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SnippetID($id)';
}

class SnippetIdGenerator {
  int id = 0;

  SnippetID idGen() {
    id += 1;
    return SnippetID(id);
  }
}

class VocalistID {
  int id;
  VocalistID(this.id);

  @override
  bool operator ==(Object other) {
    if (other is VocalistID) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VocalistID($id)';
}

class VocalistIdGenerator {
  int id = 1;

  VocalistID idGen() {
    int id = this.id;
    this.id *= 2;
    return VocalistID(id);
  }
}
