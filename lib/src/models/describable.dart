import 'identifiable.dart';

/// Домішка короткого текстового опису для сутностей з ідентифікатором.
///
/// Обмеження `on Identifiable` звужує коло класів і дає доступ до `id`.
mixin Describable on Identifiable {
  /// Коротка назва для відображення.
  String get displayName;

  /// Формує рядок `[id] displayName`.
  String describe() => '[$id] $displayName';
}

/// Домішка мітки часу останньої зміни.
mixin Timestamped on Identifiable {
  /// Момент останньої зміни (локальний час створення об'єкта).
  DateTime get updatedAt;

  /// Чи оновлено сутність протягом останніх [days] днів.
  bool updatedWithin(int days) {
    final age = DateTime.now().difference(updatedAt);
    return age.inDays <= days;
  }
}
