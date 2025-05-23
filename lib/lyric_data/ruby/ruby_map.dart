import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/position/phrase_position.dart';

class RubyMap {
  Map<PhrasePosition, Ruby> rubyMap;

  RubyMap(this.rubyMap);

  static RubyMap get empty => RubyMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<PhrasePosition, Ruby>> get entries => map.entries;
  Iterable<PhrasePosition> get keys => map.keys;
  Iterable<Ruby> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(PhrasePosition key) => map.containsKey(key);
  Ruby? operator [](PhrasePosition key) => map[key];
  void operator []=(PhrasePosition key, Ruby value) {
    map[key] = value;
  }

  Map<PhrasePosition, Ruby> get map => rubyMap;

  RubyMap concatenate(int carryUp, RubyMap other) {
    Map<PhrasePosition, Ruby> newMap = Map<PhrasePosition, Ruby>.from(rubyMap);
    for (MapEntry<PhrasePosition, Ruby> entry in other.rubyMap.entries) {
      PhrasePosition phrasePosition = entry.key;
      Ruby ruby = entry.value;
      PhrasePosition newPhrasePosition = PhrasePosition(phrasePosition.startIndex + carryUp, phrasePosition.endIndex + carryUp);
      newMap[newPhrasePosition] = ruby;
    }
    return RubyMap(newMap);
  }

  RubyMap copyWith({
    Map<PhrasePosition, Ruby>? rubyMap,
  }) {
    return RubyMap(
      rubyMap ?? this.rubyMap,
    );
  }

  @override
  String toString() {
    return rubyMap.entries.map((MapEntry<PhrasePosition, Ruby> rubyMapEntry) => '${rubyMapEntry.key}: ${rubyMapEntry.value}').join("\n");
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
