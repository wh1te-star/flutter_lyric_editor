import 'package:flutter/foundation.dart';

class VocalistCombination {
  List<String> vocalistNames;

  VocalistCombination(this.vocalistNames);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! VocalistCombination) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return listEquals(vocalistNames..sort(), other.vocalistNames..sort());
  }

  @override
  int get hashCode => vocalistNames.fold(0, (prev, element) => 31 * prev + element.hashCode);
}
