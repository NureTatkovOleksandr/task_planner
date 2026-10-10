import 'dart:async';

import 'package:task_planner/task_planner.dart';

/// Демонстраційний запуск логіки лабораторної роботи 3.
Future<void> main(List<String> arguments) async {
  Task.clearCache();
  final repo = AsyncRepository<Task>(delay: const Duration(milliseconds: 500));

  for (final line in rawTaskLines) {
    try {
      repo.seed(Task.fromCsv(line));
    } on FormatException {
      // пропускаємо пошкоджені рядки
    }
  }

  print('=== ЛР3: асинхронна та паралельна обробка ===');
  print('Засів сховища: ${repo.length} завдань');

  final sequential = Stopwatch()..start();
  await repo.load('x');
  await repo.load('y');
  await repo.load('z');
  sequential.stop();

  final parallel = Stopwatch()..start();
  await Future.wait([repo.load('x'), repo.load('y'), repo.load('z')]);
  parallel.stop();

  print(
    'Послідовні 3×500мс: ${sequential.elapsedMilliseconds} мс; '
    'паралельні Future.wait: ${parallel.elapsedMilliseconds} мс',
  );

  try {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 50)),
      Future<void>.delayed(
        const Duration(milliseconds: 50),
        () => throw StateError('збій операції'),
      ),
      Future<void>.delayed(const Duration(milliseconds: 50)),
    ]);
  } on StateError catch (e) {
    print('Future.wait спіймав: $e');
  }

  try {
    await [
      Future.value(1),
      Future<int>.error(StateError('паралельний збій')),
      Future.value(3),
    ].wait;
  } on ParallelWaitError catch (e) {
    print(
      'ParallelWaitError: values=${e.values}, '
      'errors=${e.errors}',
    );
  }

  print('Виклик без await (операція «висить» у фоні):');
  unawaited(repo.save(Task.placeholder()));
  print('  одразу після виклику length=${repo.length}');

  print('Споживання watchAll через await for:');
  var streamed = 0;
  await for (final task
      in repo.watchAll(interval: const Duration(milliseconds: 20)).take(3)) {
    streamed++;
    print('  yield: ${task.title}');
  }
  print('  отримано: $streamed');

  print('Доказ лінивості: створюємо Stream без listen/await for');
  final lazy = repo.watchAll(interval: const Duration(milliseconds: 10));
  print('  тип потоку: ${lazy.runtimeType} (генератор ще не стартував)');

  final bus = TaskEventBus();
  bus.publish(TaskCreated('demo', DateTime(2026, 9, 1), Task.placeholder()));
  bus.publish(
    TaskStatusChanged(
      'demo',
      DateTime(2026, 9, 2),
      TaskStatus.todo,
      TaskStatus.inProgress,
    ),
  );
  bus.publish(TaskDeleted('demo', DateTime(2026, 9, 3)));

  print('Події, додані до підписки (буфер single-subscription):');
  final sub = bus.events.listen((event) {
    print('  listen: ${event.runtimeType}');
  });
  await Future<void>.delayed(const Duration(milliseconds: 30));
  await sub.cancel();
  await bus.close();

  final highPriority = repo
      .watchAll(interval: const Duration(milliseconds: 5))
      .where((t) => t.priority.isHigh)
      .map((t) => t.title)
      .take(3);
  print('Конвеєр where/map/take:');
  await for (final title in highPriority) {
    print('  $title');
  }

  const limit = 120000;
  final syncWatch = Stopwatch()..start();
  final syncPrimes = countPrimesUpTo(limit);
  syncWatch.stop();
  final beforeShared = sharedCounter;

  final isoWatch = Stopwatch()..start();
  final isoPrimes = await countPrimesInIsolate(limit);
  isoWatch.stop();

  print(
    'Прості до $limit: sync=$syncPrimes (${syncWatch.elapsedMilliseconds} мс), '
    'isolate=$isoPrimes (${isoWatch.elapsedMilliseconds} мс)',
  );
  print(
    'sharedCounter до Isolate.run=$beforeShared, '
    'після=$sharedCounter (ізолят не змінює глобальну змінну головного ізоляту)',
  );
}
