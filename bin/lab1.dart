import 'package:task_planner/task_planner.dart';

/// Демонстраційний запуск логіки лабораторної роботи 1.
void main(List<String> arguments) {
  final counter = createProcessedCounter();
  final tasks = <TaskRecord>[];
  final parseErrors = <String>[];
  final validationErrors = <String>[];

  for (final line in rawTaskLines) {
    counter.increment();
    final outcome = parseLine(line);
    if (outcome.task == null) {
      parseErrors.add(outcome.error!);
      continue;
    }
    final violations = validateTask(outcome.task!);
    if (violations.isNotEmpty) {
      validationErrors.addAll(violations);
      continue;
    }
    tasks.add(outcome.task!);
  }

  print('Оброблено рядків: ${counter.read()}');
  print('Валідних завдань: ${tasks.length}');
  print('Помилок розбору: ${parseErrors.length}');
  for (final error in parseErrors) {
    print('  ! $error');
  }
  if (validationErrors.isNotEmpty) {
    print('Порушень валідації: ${validationErrors.length}');
    for (final error in validationErrors) {
      print('  ! $error');
    }
  }

  print('');
  print('Фільтр: статус done');
  for (final summary in mapToSummaries(filterByStatus(tasks, 'done'))) {
    print('  - $summary');
  }

  print('');
  print('Високий пріоритет (>=4):');
  final highPriority = tasks.where(priorityAtLeast(4)).toList();
  for (final summary in mapToSummaries(highPriority)) {
    print('  - $summary');
  }

  print('');
  print('Демонстрація маскування назви проєкту:');
  const sampleProject = 'Інфраструктура';
  print('  було: $sampleProject');
  print('  стало: ${maskProjectName(sampleProject)}');

  print('');
  print(buildReport(tasks, topCount: 5, ascending: false));

  print('Сортування за терміном (criterion: deadline, ascending: true):');
  for (final task in sortTasks(
    tasks,
    ascending: true,
    criterion: SortCriterion.deadline,
  ).take(5)) {
    print(
      '  ${task.deadline.toIso8601String().substring(0, 10)} ${task.title}',
    );
  }

  print('');
  print('Сортування за пріоритетом (criterion: priority, ascending: false):');
  for (final task in sortTasks(
    tasks,
    ascending: false,
    criterion: SortCriterion.priority,
  ).take(5)) {
    print('  P${task.priority} ${task.title}');
  }
}
