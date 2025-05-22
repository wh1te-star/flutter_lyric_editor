import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id_generator.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';

class VocalistColorMap {
  String vocalistNameSeparator = ", ";
  final Map<VocalistID, Vocalist> _vocalistColorMap;
  static final VocalistIdGenerator idGenerator = VocalistIdGenerator();

  VocalistColorMap(this._vocalistColorMap);

  Map<VocalistID, Vocalist> get map => _vocalistColorMap;

  static VocalistColorMap get empty => VocalistColorMap({});
  bool get isEmpty => map.isEmpty;

  Iterable<MapEntry<VocalistID, Vocalist>> get entries => map.entries;
  Iterable<VocalistID> get keys => map.keys;
  Iterable<Vocalist> get values => map.values;
  int get length => map.length;
  void clear() => map.clear();
  bool containsKey(VocalistID key) => map.containsKey(key);
  Vocalist? operator [](VocalistID key) => map[key];
  void operator []=(VocalistID key, Vocalist value) {
    map[key] = value;
  }

  Vocalist getVocalistByID(VocalistID id) {
    return map.entries
        .where((MapEntry<VocalistID, Vocalist> entry) {
          VocalistID vocalistID = entry.key;
          return vocalistID == id;
        })
        .first
        .value;
  }

  Vocalist getVocalistByName(String name) {
    return map.entries
        .where((MapEntry<VocalistID, Vocalist> entry) {
          String vocalistName = entry.value.name;
          return vocalistName == name;
        })
        .first
        .value;
  }

  VocalistID getVocalistIDByName(String name) {
    return map.entries
        .where((MapEntry<VocalistID, Vocalist> entry) {
          String vocalistName = entry.value.name;
          return vocalistName == name;
        })
        .first
        .key;
  }

  VocalistColorMap addVocalist(Vocalist vocalist) {
    final Map<VocalistID, Vocalist> newMap = Map<VocalistID, Vocalist>.from(map);
    newMap[idGenerator.idGen()] = vocalist;
    return VocalistColorMap(newMap);
  }

  VocalistColorMap addVocalistCombination(List<String> vocalistNames, int color) {
    final Map<VocalistID, Vocalist> newMap = Map<VocalistID, Vocalist>.from(map);

    int combinationID = 0;
    for (String vocalistName in vocalistNames) {
      combinationID += getVocalistIDByName(vocalistName).id;
    }

    String joinedName = vocalistNames.join(', ');
    newMap[VocalistID(combinationID)] = Vocalist(name: joinedName, color: color + 0xFF000000);

    return VocalistColorMap(newMap);
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

  VocalistColorMap removeVocalistByID(VocalistID id) {
    final Map<VocalistID, Vocalist> copiedMap = Map<VocalistID, Vocalist>.from(map);
    copiedMap.remove(id);
    return VocalistColorMap(copiedMap);
  }

  VocalistColorMap changeVocalistName(String oldName, String newName) {
    final Map<VocalistID, Vocalist> copiedMap = Map<VocalistID, Vocalist>.from(map);

    VocalistID vocalistID = getVocalistIDByName(oldName);
    for (MapEntry<VocalistID, Vocalist> entry in copiedMap.entries) {
      VocalistID id = entry.key;
      Vocalist vocalist = entry.value;
      if (isBitTrue(id, vocalistID)) {
        vocalist.name = generateVocalistCombinationNameFromID(id);
      }
    }
    return VocalistColorMap(copiedMap);
  }

  bool isBitTrue(VocalistID targetID, VocalistID singleID) {
    return (targetID.id & singleID.id) != 0;
  }

  String generateVocalistCombinationNameFromID(VocalistID vocalistID) {
    int signalBitID = 1;
    String vocalistName = "";
    while (signalBitID < map.keys.toList().last.id) {
      if (isBitTrue(vocalistID, VocalistID(signalBitID))) {
        vocalistName += vocalistNameSeparator;
        vocalistName += map[VocalistID(signalBitID)]!.name;
      }
      signalBitID *= 2;
    }

    vocalistName = vocalistName.substring(vocalistNameSeparator.length);
    return vocalistName;
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
