import 'task.dart';
import 'task_status.dart';

/// Корисні розширення рядка для предметної області.
extension TaskStringX on String {
  /// Нормалізує назву проєкту: trim + стиснення пробілів.
  String get normalizedProject => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Чи схожий рядок на код статусу завдання.
  bool get looksLikeTaskStatus => TaskStatus.tryParse(this) != null;
}

/// Розширення для колекцій завдань.
extension TaskIterableX on Iterable<Task> {
  /// Сумарна трудомісткість.
  double get totalEffort => fold(0.0, (sum, t) => sum + t.effortHours);

  /// Лише незавершені завдання.
  Iterable<Task> get openOnly => where((t) => t.status != TaskStatus.done);
}
