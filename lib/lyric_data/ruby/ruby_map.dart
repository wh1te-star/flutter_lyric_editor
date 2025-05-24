import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/position/word_range.dart';

class RubyMap {
  Map<WordRange, Ruby> rubyMap;

  RubyMap(this.rubyMap);

  static RubyMap get empty => RubyMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<WordRange, Ruby>> get entries => map.entries;
  Iterable<WordRange> get keys => map.keys;
  Iterable<Ruby> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(WordRange key) => map.containsKey(key);
  Ruby? operator [](WordRange key) => map[key];
  void operator []=(WordRange key, Ruby value) {
    map[key] = value;
  }

  Map<WordRange, Ruby> get map => rubyMap;

  RubyMap concatenate(int carryUp, RubyMap other) {
    Map<WordRange, Ruby> newMap = Map<WordRange, Ruby>.from(rubyMap);
    for (MapEntry<WordRange, Ruby> entry in other.rubyMap.entries) {
      WordRange wordRange = entry.key;
      Ruby ruby = entry.value;
      WordRange newWordRange = WordRange(wordRange.startIndex + carryUp, wordRange.endIndex + carryUp);
      newMap[newWordRange] = ruby;
    }
    return RubyMap(newMap);
  }

  RubyMap copyWith({
    Map<WordRange, Ruby>? rubyMap,
  }) {
    return RubyMap(
      rubyMap ?? this.rubyMap,
    );
  }

  @override
  String toString() {
    return rubyMap.entries.map((MapEntry<WordRange, Ruby> rubyMapEntry) => '${rubyMapEntry.key}: ${rubyMapEntry.value}').join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RubyMap) return false;
    return const DeepCollectionEquality().equals(rubyMap, other.rubyMap);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(rubyMap);
}
