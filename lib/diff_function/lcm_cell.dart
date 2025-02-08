class LCMCell {
  final bool fromLeft;
  final bool fromUpper;
  final bool fromLeftUpper;
  final int lcmLength;

  LCMCell({
    required this.fromLeft,
    required this.fromUpper,
    required this.fromLeftUpper,
    required this.lcmLength,
  }) {
    assert(lcmLength >= 0);
  }

  @override
  String toString() {
    if (fromLeftUpper) {
      return "↖↖";
    } else {
      String leftChar = " ";
      String upperChar = " ";
      if (fromLeft) leftChar = "←";
      if (fromUpper) upperChar = "↑";
      return "$leftChar$upperChar";
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! LCMCell) return false;
    if (runtimeType != other.runtimeType) return false;
    if (fromLeft != other.fromLeft) return false;
    if (fromUpper != other.fromUpper) return false;
    if (fromLeftUpper != other.fromLeftUpper) return false;
    if (lcmLength != other.lcmLength) return false;
    return true;
  }

  @override
  int get hashCode {
    int hash = fromLeft.hashCode;
    hash ^= fromUpper.hashCode;
    hash ^= fromLeftUpper.hashCode;
    hash ^= lcmLength.hashCode;
    return hash;
  }
}
