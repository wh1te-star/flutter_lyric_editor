class SortedList<T extends Comparable> {
  List<T> _list = [];

  SortedList([Iterable<T>? elements]) {
    if (elements != null) {
      for (var element in elements) {
        add(element);
      }
    }
  }

  void add(T element) {
    int index = _list.indexWhere((e) => e.compareTo(element) > 0);
    if (index == -1) {
      _list.add(element);
    } else {
      _list.insert(index, element);
    }
  }

  void remove(T element) {
    _list.remove(element);
  }

  List<T> get list => List.unmodifiable(_list);
}

class SortedMap<K extends Comparable, V> implements Map<K, V> {
  final Map<K, V> _map = {};

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, V value) {
    _map[key] = value;
    _sortKeys();
  }

  @override
  void clear() => _map.clear();

  @override
  Iterable<K> get keys => _map.keys.toList()..sort();

  @override
  Iterable<V> get values => keys.map((key) => _map[key]!);

  @override
  int get length => _map.length;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  void addAll(Map<K, V> other) {
    _map.addAll(other);
    _sortKeys();
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  @override
  void forEach(void Function(K key, V value) action) {
    for (var key in keys) {
      action(key, _map[key]!);
    }
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final result = _map.putIfAbsent(key, ifAbsent);
    _sortKeys();
    return result;
  }

  @override
  V? remove(Object? key) {
    final result = _map.remove(key);
    _sortKeys();
    return result;
  }

  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _map.addEntries(newEntries);
    _sortKeys();
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    return _map.map(convert);
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final result = _map.update(key, update, ifAbsent: ifAbsent);
    _sortKeys();
    return result;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _map.updateAll(update);
    _sortKeys();
  }

  @override
  Iterable<MapEntry<K, V>> get entries => keys.map((key) => MapEntry(key, _map[key]!));

  @override
  void removeWhere(bool Function(K key, V value) test) {
    _map.removeWhere(test);
    _sortKeys();
  }

  void _sortKeys() {
    final sortedEntries = _map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    _map
      ..clear()
      ..addEntries(sortedEntries);
  }
}
