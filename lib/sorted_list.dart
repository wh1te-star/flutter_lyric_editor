class SortedList<T extends Comparable> {
  List<T> _list = [];

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