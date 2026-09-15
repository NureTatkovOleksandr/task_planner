import 'package:task_planner/task_planner.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncRepository', () {
    late AsyncRepository<Task> repo;
    late Task sample;

    setUp(() {
      Task.clearCache();
      repo = AsyncRepository<Task>(delay: Duration.zero);
      sample = Task(
        'Тест',
        'Demo',
        const HighPriority(),
        DateTime(2026, 10, 1),
        TaskStatus.todo,
        3,
      );
    });

    test('save і load повертають збережене завдання', () async {
      await repo.save(sample);
      final loaded = await repo.load(sample.id);
      expect(loaded, equals(sample));
    });

    test('load повертає null для відсутнього id', () async {
      expect(await repo.load('missing'), isNull);
    });

    test('remove повертає true лише для наявного id', () async {
      await repo.save(sample);
      expect(await repo.remove(sample.id), isTrue);
      expect(await repo.remove(sample.id), isFalse);
    });

    test('loadAll повертає всі збережені елементи', () async {
      await repo.save(sample);
      await repo.save(Task.placeholder());
      final all = await repo.loadAll();
      expect(all, hasLength(2));
    });
  });

  group('watchAll stream', () {
    test('події йдуть у порядку додавання', () async {
      Task.clearCache();
      final repo = AsyncRepository<Task>(delay: Duration.zero);
      final first = Task(
        'A',
        'P',
        const LowPriority(),
        DateTime(2026, 1, 1),
        TaskStatus.todo,
        1,
      );
      final second = Task(
        'B',
        'P',
        const LowPriority(),
        DateTime(2026, 1, 2),
        TaskStatus.todo,
        1,
      );
      repo.seed(first);
      repo.seed(second);

      await expectLater(
        repo.watchAll(interval: Duration.zero).map((t) => t.title),
        emitsInOrder(['A', 'B', emitsDone]),
      );
    });

    test('помилка в шині подій передається слухачу', () async {
      final bus = TaskEventBus(broadcast: true);
      final expectation = expectLater(
        bus.events,
        emitsError(isA<StateError>()),
      );
      bus.publishError(StateError('stream boom'));
      await expectation;
      await bus.close();
    });
  });
}
