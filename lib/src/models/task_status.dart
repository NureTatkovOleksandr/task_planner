/// Статус завдання з додатковими членами перелічення.
enum TaskStatus {
  /// Завдання ще не розпочато.
  todo('todo', 'До виконання'),

  /// Завдання виконується.
  inProgress('in_progress', 'В роботі'),

  /// Завдання завершено.
  done('done', 'Виконано');

  const TaskStatus(this.code, this.label);

  /// Код статусу в CSV/JSON.
  final String code;

  /// Людиночитна мітка.
  final String label;

  /// Чи вважається статус завершеним.
  bool get isClosed => this == TaskStatus.done;

  /// Розбирає код статусу або повертає `null`.
  static TaskStatus? tryParse(String raw) {
    for (final value in TaskStatus.values) {
      if (value.code == raw) {
        return value;
      }
    }
    return null;
  }
}
