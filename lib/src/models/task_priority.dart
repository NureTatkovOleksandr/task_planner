/// Запечатана ієрархія пріоритетів завдання.
sealed class TaskPriority {
  /// Створює пріоритет із числовим рівнем.
  const TaskPriority(this.level);

  /// Числовий рівень пріоритету (1–5).
  final int level;

  /// Людиночитна назва пріоритету.
  String get title;

  /// Чи є пріоритет високим (рівень ≥ 4).
  bool get isHigh => level >= 4;

  /// Будує пріоритет за числовим рівнем.
  static TaskPriority fromLevel(int level) {
    return switch (level) {
      1 => const LowPriority(),
      2 => const BelowNormalPriority(),
      3 => const NormalPriority(),
      4 => const HighPriority(),
      5 => const CriticalPriority(),
      _ => throw ArgumentError.value(level, 'level', 'Очікується 1..5'),
    };
  }
}

/// Низький пріоритет.
final class LowPriority extends TaskPriority {
  /// Створює низький пріоритет.
  const LowPriority() : super(1);

  @override
  String get title => 'Низький';
}

/// Пріоритет нижче середнього.
final class BelowNormalPriority extends TaskPriority {
  /// Створює пріоритет нижче середнього.
  const BelowNormalPriority() : super(2);

  @override
  String get title => 'Нижче середнього';
}

/// Звичайний пріоритет.
final class NormalPriority extends TaskPriority {
  /// Створює звичайний пріоритет.
  const NormalPriority() : super(3);

  @override
  String get title => 'Звичайний';
}

/// Високий пріоритет.
final class HighPriority extends TaskPriority {
  /// Створює високий пріоритет.
  const HighPriority() : super(4);

  @override
  String get title => 'Високий';
}

/// Критичний пріоритет.
final class CriticalPriority extends TaskPriority {
  /// Створює критичний пріоритет.
  const CriticalPriority() : super(5);

  @override
  String get title => 'Критичний';
}

/// Повертає мітку пріоритету без гілки `default` (вичерпний switch).
String priorityLabel(TaskPriority priority) {
  return switch (priority) {
    LowPriority() => 'P1',
    BelowNormalPriority() => 'P2',
    NormalPriority() => 'P3',
    HighPriority() => 'P4',
    CriticalPriority() => 'P5',
  };
}
