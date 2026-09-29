import 'package:task_planner/task_planner.dart';

/// Демонстраційний запуск логіки лабораторної роботи 2.
void main(List<String> arguments) {
  Task.clearCache();
  final repo = Repository<Task>();
  final parseErrors = <String>[];

  for (final line in rawTaskLines) {
    try {
      final task = Task.fromCsv(line);
      final record = parseLine(line).task;
      if (record != null) {
        final violations = validateTask(record);
        if (violations.isNotEmpty) {
          parseErrors.addAll(violations);
          continue;
        }
      }
      repo.add(task);
    } on FormatException catch (e) {
      parseErrors.add(e.message);
    }
  }

  final tasks = repo.all.toList();
  print('=== ЛР2: ООП-модель предметної області ===');
  print('Валідних завдань у сховищі: ${repo.length}');
  print('Помилок розбору: ${parseErrors.length}');
  for (final error in parseErrors) {
    print('  ! $error');
  }

  print('');
  print('Описи (домішка Describable):');
  for (final task in tasks.take(3)) {
    print('  ${task.describe()}');
  }

  print('');
  print(formatSummary(summarize(tasks)));

  print('');
  print('Оцінка ризику (pattern matching):');
  for (final task in tasks.where((t) => t.priority.isHigh).take(5)) {
    print('  ${task.title}: ${riskLabel(task)}');
  }

  print('');
  print('Перевірка == / hashCode у Set:');
  final a = Task(
    'Один і той самий',
    'Demo',
    const HighPriority(),
    DateTime(2026, 10, 1),
    TaskStatus.todo,
    4,
  );
  final b = Task(
    'Один і той самий',
    'Demo',
    const HighPriority(),
    DateTime(2026, 10, 1),
    TaskStatus.todo,
    4,
  );
  print('  a == b: ${a == b}');
  print('  Set.size: ${{a, b}.length}');

  print('');
  print('Розширення Iterable: відкриті завдання = ${tasks.openOnly.length}');
  print('Сумарна трудомісткість: ${tasks.totalEffort} год');
  print('Нормалізація проєкту: ${'  Dart   Lab  '.normalizedProject}');

  print('');
  print('Пріоритети (sealed switch):');
  for (final level in [1, 3, 5]) {
    final p = TaskPriority.fromLevel(level);
    print('  ${p.title} -> ${priorityLabel(p)}');
  }

  print('');
  final project = Project('Dart Lab');
  print('Проєкт з домішками: ${project.describe()}');
}
