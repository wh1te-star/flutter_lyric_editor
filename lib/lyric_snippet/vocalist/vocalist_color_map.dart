import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id_generator.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id_generator.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';

class VocalistColorMap {
  final Map<VocalistID, Vocalist> _vocalistColorMap;
  final VocalistIdGenerator idGenerator = VocalistIdGenerator();

  VocalistColorMap(this._vocalistColorMap);

  Map<VocalistID, Vocalist> get map => _vocalistColorMap;

  static VocalistColorMap get empty => VocalistColorMap({});

  bool get isEmpty => map.isEmpty;

  VocalistColorMap addVocalist(String name, int color) {
    final Map<VocalistID, Vocalist> newMap = Map<VocalistID, Vocalist>.from(map);
    newMap[idGenerator.idGen()] = Vocalist(name: name, color: color);
    return VocalistColorMap(newMap);
  }

  VocalistColorMap removeVocalistByID(VocalistID id) {
    final Map<VocalistID, Vocalist> copiedMap = Map<VocalistID, Vocalist>.from(map);
    copiedMap.remove(id);
    return VocalistColorMap(copiedMap);
  }

  VocalistColorMap removeVocalistByName(String name) {
    final Map<VocalistID, Vocalist> copiedMap = Map<VocalistID, Vocalist>.from(map);
    final VocalistID vocalistID = copiedMap.entries
        .firstWhere(
          (MapEntry<VocalistID, Vocalist> entry) => entry.value.name == name,
          orElse: () => MapEntry(VocalistID.empty, Vocalist(name: '', color: 0)),
        )
        .key;

    if (!vocalistID.isEmpty) {
      copiedMap.remove(vocalistID);
    }
    return VocalistColorMap(copiedMap);
  }

  VocalistColorMap copyWith({
    Map<VocalistID, Vocalist>? vocalistColorMap,
  }) {
    return VocalistColorMap({...(vocalistColorMap ?? map)}.map((key, value) => MapEntry(key, value.copyWith())));
  }

  @override
  String toString() {
    return map.values.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VocalistColorMap) return false;
    if (map.length != other.map.length) return false;
    return map.keys.every((key) {
      return map[key] == other.map[key];
    });
  }

  @override
  int get hashCode => map.entries.fold(0, (hash, entry) {
        return hash ^ entry.key.hashCode ^ entry.value.hashCode;
      });
}
