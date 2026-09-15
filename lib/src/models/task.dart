import '../task_processing.dart';
import 'describable.dart';
import 'identifiable.dart';
import 'task_priority.dart';
import 'task_status.dart';

/// Незмінна сутність «завдання» предметної області (первинний конструктор).
final class Task(
  /// Назва завдання.
  final String title,

  /// Назва проєкту.
  final String project,

  /// Пріоритет завдання.
  final TaskPriority priority,

  /// Термін виконання.
  final DateTime deadline,

  /// Поточний статус.
  final TaskStatus status,

  /// Оцінка трудомісткості в годинах.
  final double effortHours, [

  /// Момент останньої зміни; якщо не задано — епоха Unix (детермінізм у тестах).
  final DateTime? lastUpdated,
]) extends Identifiable with Describable, Timestamped {
  /// Ідентифікатор будується з назви, проєкту та терміну.
  @override
  String get id => _buildId(title, project, deadline);

  /// Іменований конструктор розбору CSV-рядка.
  ///
  /// Кидає [FormatException], якщо рядок пошкоджений.
  factory Task.fromCsv(String line) {
    final outcome = parseLine(line);
    if (outcome.task == null) {
      throw FormatException(outcome.error ?? 'Некоректний CSV');
    }
    final record = outcome.task!;
    final key = _buildId(record.title, record.project, record.deadline);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final task = Task(
      record.title,
      record.project,
      TaskPriority.fromLevel(record.priority),
      record.deadline,
      TaskStatus.tryParse(record.status)!,
      record.effortHours,
    );
    return Task._cached(task);
  }

  /// Фабричний конструктор із кешуванням за ідентифікатором.
  factory Task._cached(Task task) {
    return _cache.putIfAbsent(task.id, () => task);
  }

  /// Повертає завдання-заглушку для відсутніх даних.
  factory Task.placeholder() {
    return Task(
      'Невідоме завдання',
      'N/A',
      const NormalPriority(),
      DateTime(2099, 1, 1),
      TaskStatus.todo,
      minEffortHours,
    );
  }

  static final Map<String, Task> _cache = {};

  static String _buildId(String title, String project, DateTime deadline) {
    return '${project.toLowerCase()}::${title.toLowerCase()}::'
        '${deadline.toIso8601String().substring(0, 10)}';
  }

  /// Очищає кеш фабричного конструктора (для тестів і демо).
  static void clearCache() => _cache.clear();

  @override
  DateTime get updatedAt =>
      lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String get displayName => title;

  /// Кількість днів до або після терміну відносно [reference].
  int ageInDays({DateTime? reference}) {
    final now = reference ?? DateTime(2026, 9, 20);
    return now.difference(deadline).inDays.abs();
  }

  /// Чи прострочено завдання на [reference].
  bool isOverdue({DateTime? reference}) {
    final now = reference ?? DateTime(2026, 9, 20);
    return !status.isClosed && deadline.isBefore(now);
  }

  /// JSON-представлення завдання.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'project': project,
    'priority': priority.level,
    'deadline': deadline.toIso8601String().substring(0, 10),
    'status': status.code,
    'effortHours': effortHours,
  };

  /// Відновлює завдання з JSON-мапи.
  factory Task.fromJson(Map<String, Object?> json) {
    return Task(
      json['title'] as String,
      json['project'] as String,
      TaskPriority.fromLevel(json['priority'] as int),
      DateTime.parse(json['deadline'] as String),
      TaskStatus.tryParse(json['status'] as String)!,
      (json['effortHours'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'Task($title, $project, ${priorityLabel(priority)}, '
      '${status.code}, ${effortHours}h)';

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.title == title &&
        other.project == project &&
        other.priority.level == priority.level &&
        other.deadline == deadline &&
        other.status == status &&
        other.effortHours == effortHours;
  }

  @override
  int get hashCode => Object.hash(
    title,
    project,
    priority.level,
    deadline,
    status,
    effortHours,
  );
}
