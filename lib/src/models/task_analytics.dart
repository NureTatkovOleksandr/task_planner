import 'task.dart';
import 'task_priority.dart';
import 'task_status.dart';

/// Підсумок агрегації: кількість і сумарна трудомісткість.
typedef EffortSummary = ({int count, double totalEffort});

/// Обчислює підсумок для списку [tasks].
EffortSummary summarize(List<Task> tasks) {
  return (
    count: tasks.length,
    totalEffort: tasks.fold(0.0, (sum, t) => sum + t.effortHours),
  );
}

/// Розбирає підсумок через деструктуризацію запису.
String formatSummary(EffortSummary summary) {
  final (:count, :totalEffort) = summary;
  return 'Записів: $count, трудомісткість: ${totalEffort.toStringAsFixed(1)} год';
}

/// Повертає текстову оцінку ризику за пріоритетом і статусом зі зразком `when`.
String riskLabel(Task task) {
  return switch (task) {
    Task(priority: CriticalPriority(), status: TaskStatus.todo) =>
      'критичний ризик',
    Task(priority: HighPriority(), status: TaskStatus.todo)
        when task.isOverdue() =>
      'прострочено з високим пріоритетом',
    Task(status: TaskStatus.done) => 'без ризику',
    Task(priority: TaskPriority(level: final level)) when level >= 4 =>
      'підвищена увага',
    _ => 'звичайний контроль',
  };
}
