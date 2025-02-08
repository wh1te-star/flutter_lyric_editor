class LCSCell {
  final bool fromLeft;
  final bool fromUpper;
  final bool fromLeftUpper;
  final int lcsLength;

  LCSCell({
    required this.fromLeft,
    required this.fromUpper,
    required this.fromLeftUpper,
    required this.lcsLength,
  }) {
    assert(lcsLength >= 0);
  }

  @override
  String toString() {
    if (fromLeftUpper) {
      return "↖↖$lcsLength";
    } else {
      String leftChar = " ";
      String upperChar = " ";
      if (fromLeft) leftChar = "←";
      if (fromUpper) upperChar = "↑";
      return "$leftChar$upperChar$lcsLength";
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! LCSCell) return false;
    if (runtimeType != other.runtimeType) return false;
    if (fromLeft != other.fromLeft) return false;
    if (fromUpper != other.fromUpper) return false;
    if (fromLeftUpper != other.fromLeftUpper) return false;
    if (lcsLength != other.lcsLength) return false;
    return true;
  }

  @override
  int get hashCode {
    int hash = fromLeft.hashCode;
    hash ^= fromUpper.hashCode;
    hash ^= fromLeftUpper.hashCode;
    hash ^= lcsLength.hashCode;
    return hash;
  }
}
