class VocalistID {
  int id;
  VocalistID(this.id);

  static VocalistID get empty {
    return VocalistID(0);
  }

  bool isEmpty() {
    return id == 0;
  }

  VocalistID copyWith({int? id}) {
    return VocalistID(id ?? this.id);
  }

  @override
  String toString() => 'VocalistID($id)';

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
}