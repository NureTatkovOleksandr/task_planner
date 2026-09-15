import 'identifiable.dart';

/// Сховище сутностей, які вміють повідомляти власний ідентифікатор.
class Repository<T extends Identifiable> {
  final Map<String, T> _items = {};

  /// Додає або оновлює сутність [item].
  void add(T item) => _items[item.id] = item;

  /// Повертає сутність за [id] або `null`.
  T? findById(String id) => _items[id];

  /// Усі збережені сутності.
  Iterable<T> get all => _items.values;

  /// Кількість збережених сутностей.
  int get length => _items.length;

  /// Фільтрує сутності предикатом [test].
  Iterable<T> where(bool Function(T) test) => _items.values.where(test);

  /// Видаляє сутність за [id].
  bool remove(String id) => _items.remove(id) != null;

  /// Очищає сховище.
  void clear() => _items.clear();
}
