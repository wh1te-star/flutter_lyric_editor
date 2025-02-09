class Vocalist {
  String name;
  int color;
  Vocalist({
    required this.name,
    required this.color,
  });

  Vocalist copyWith({
    String? name,
    int? color,
  }) {
    return Vocalist(
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Vocalist otherVocalist = other as Vocalist;
    return name == otherVocalist.name && color == otherVocalist.color;
  }

  @override
  int get hashCode => Object.hash(name, color);
}
