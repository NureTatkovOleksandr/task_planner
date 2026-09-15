import 'dart:async';

import '../models/identifiable.dart';
import '../models/task.dart';

/// Асинхронне сховище сутностей предметної області.
class AsyncRepository<T extends Identifiable> {
  /// Створює сховище з опційною початковою затримкою операцій.
  AsyncRepository({this.delay = const Duration(milliseconds: 300)});

  /// Затримка імітації доступу до даних.
  final Duration delay;

  final Map<String, T> _items = {};

  /// Зберігає сутність [item].
  Future<void> save(T item) async {
    await Future<void>.delayed(delay);
    _items[item.id] = item;
  }

  /// Повертає сутність за ідентифікатором [id] або `null`.
  Future<T?> load(String id) async {
    await Future<void>.delayed(delay);
    return _items[id];
  }

  /// Видаляє сутність за [id].
  Future<bool> remove(String id) async {
    await Future<void>.delayed(delay);
    return _items.remove(id) != null;
  }

  /// Повертає всі сутності.
  Future<List<T>> loadAll() async {
    await Future<void>.delayed(delay);
    return _items.values.toList();
  }

  /// Видає сутності по одній у міру «надходження».
  Stream<T> watchAll({
    Duration interval = const Duration(milliseconds: 100),
  }) async* {
    print('async*: генератор почав роботу');
    for (final item in _items.values) {
      await Future<void>.delayed(interval);
      yield item;
    }
  }

  /// Додає елемент синхронно (для підготовки демо/тестів).
  void seed(T item) => _items[item.id] = item;

  /// Кількість елементів без затримки.
  int get length => _items.length;
}

/// Типізоване сховище завдань.
typedef TaskAsyncRepository = AsyncRepository<Task>;
