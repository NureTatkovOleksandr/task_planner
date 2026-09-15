import 'dart:async';

import '../models/task.dart';
import '../models/task_status.dart';

/// Подія зміни стану завдання.
sealed class TaskEvent {
  /// Спільний конструктор події.
  const TaskEvent(this.taskId, this.at);

  /// Ідентифікатор завдання.
  final String taskId;

  /// Час події.
  final DateTime at;
}

/// Завдання створено.
final class TaskCreated extends TaskEvent {
  /// Створює подію створення.
  const TaskCreated(super.taskId, super.at, this.task);

  /// Створене завдання.
  final Task task;
}

/// Статус завдання змінено.
final class TaskStatusChanged extends TaskEvent {
  /// Створює подію зміни статусу.
  const TaskStatusChanged(super.taskId, super.at, this.from, this.to);

  /// Попередній статус.
  final TaskStatus from;

  /// Новий статус.
  final TaskStatus to;
}

/// Завдання видалено.
final class TaskDeleted extends TaskEvent {
  /// Створює подію видалення.
  const TaskDeleted(super.taskId, super.at);
}

/// Джерело подій предметної області на базі [StreamController].
class TaskEventBus {
  /// Створює шину подій.
  ///
  /// [broadcast] вмикає широкомовний режим.
  TaskEventBus({bool broadcast = false})
    : _controller = broadcast
          ? StreamController<TaskEvent>.broadcast()
          : StreamController<TaskEvent>();

  final StreamController<TaskEvent> _controller;

  /// Потік подій.
  Stream<TaskEvent> get events => _controller.stream;

  /// Чи є шина закритою.
  bool get isClosed => _controller.isClosed;

  /// Публікує подію [event].
  void publish(TaskEvent event) => _controller.add(event);

  /// Публікує помилку в потік.
  void publishError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  /// Закриває шину.
  Future<void> close() => _controller.close();
}
