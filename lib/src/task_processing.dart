/// Мінімальний пріоритет завдання.
const int minPriority = 1;

/// Максимальний пріоритет завдання.
const int maxPriority = 5;

/// Мінімальна оцінка трудомісткості в годинах.
const double minEffortHours = 0.5;

/// Максимальна оцінка трудомісткості в годинах.
const double maxEffortHours = 80;

/// Роздільник полів CSV-рядка.
const String csvSeparator = ';';

/// Шаблон перевірки статусу з іменованими групами.
final RegExp statusPattern = RegExp(r'^(?<status>todo|in_progress|done)$');

/// Шаблон дати ISO `YYYY-MM-DD` з іменованими групами.
final RegExp isoDatePattern = RegExp(
  r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
);

/// Запис завдання предметної області (без класів — лише record).
typedef TaskRecord = ({
  String title,
  String project,
  int priority,
  DateTime deadline,
  String status,
  double effortHours,
});

/// Результат розбору рядка: або запис, або опис помилки.
typedef ParseOutcome = ({TaskRecord? task, String? error});

/// Розбирає рядок [line] у запис завдання.
///
/// Повертає `null` у полі `task`, якщо рядок не відповідає очікуваному формату.
ParseOutcome parseLine(String line) {
  final parts = line.split(csvSeparator);
  if (parts.length != 6) {
    return (
      task: null,
      error: 'Очікувалось 6 полів, отримано ${parts.length}: "$line"',
    );
  }

  final title = parts[0].trim();
  final project = parts[1].trim();
  final priority = int.tryParse(parts[2].trim());
  final dateRaw = parts[3].trim();
  final status = parts[4].trim();
  final effortHours = double.tryParse(parts[5].trim());

  if (title.isEmpty) {
    return (task: null, error: 'Порожня назва завдання');
  }
  if (project.isEmpty) {
    return (task: null, error: 'Порожня назва проєкту');
  }
  if (priority == null) {
    return (task: null, error: 'Некоректний пріоритет у рядку: "$line"');
  }

  final dateMatch = isoDatePattern.firstMatch(dateRaw);
  if (dateMatch == null) {
    return (task: null, error: 'Некоректний формат дати у рядку: "$line"');
  }
  final year = int.parse(dateMatch.namedGroup('year')!);
  final month = int.parse(dateMatch.namedGroup('month')!);
  final day = int.parse(dateMatch.namedGroup('day')!);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return (task: null, error: 'Некоректна дата терміну у рядку: "$line"');
  }
  final deadline = DateTime(year, month, day);
  if (deadline.year != year || deadline.month != month || deadline.day != day) {
    return (task: null, error: 'Некоректна дата терміну у рядку: "$line"');
  }

  if (effortHours == null) {
    return (task: null, error: 'Некоректна трудомісткість у рядку: "$line"');
  }

  final match = statusPattern.firstMatch(status);
  if (match == null) {
    return (task: null, error: 'Некоректний статус "$status" у рядку: "$line"');
  }

  final normalizedStatus = match.namedGroup('status')!;
  return (
    task: (
      title: title,
      project: project,
      priority: priority,
      deadline: deadline,
      status: normalizedStatus,
      effortHours: effortHours,
    ),
    error: null,
  );
}

/// Перевіряє діапазони значень запису [task] і повертає перелік порушень.
List<String> validateTask(TaskRecord task) {
  final violations = <String>[];
  if (task.priority < minPriority || task.priority > maxPriority) {
    violations.add(
      'Пріоритет ${task.priority} поза діапазоном '
      '[$minPriority;$maxPriority] для "${task.title}"',
    );
  }
  if (task.effortHours < minEffortHours || task.effortHours > maxEffortHours) {
    violations.add(
      'Трудомісткість ${task.effortHours} поза діапазоном '
      '[$minEffortHours;$maxEffortHours] для "${task.title}"',
    );
  }
  return violations;
}

/// Фабрика предикатів: повертає замикання, що фільтрує за мінімальним пріоритетом.
bool Function(TaskRecord) priorityAtLeast(int min) {
  return (task) => task.priority >= min;
}

/// Лічильник оброблених записів: збільшення та читання без побічних ефектів.
typedef ProcessedCounter = ({void Function() increment, int Function() read});

/// Створює лічильник оброблених записів у вигляді замикання.
///
/// Захоплює змінну лічильника; [increment] змінює її, [read] лише читає.
ProcessedCounter createProcessedCounter() {
  var count = 0;
  return (
    increment: () {
      count += 1;
    },
    read: () => count,
  );
}

/// Критерій сортування завдань.
enum SortCriterion {
  /// Сортувати спочатку за пріоритетом, потім за терміном.
  priority,

  /// Сортувати спочатку за терміном, потім за пріоритетом.
  deadline,
}

/// Маскує назву проєкту: залишає перший і останній символи, решту замінює на `*`.
String maskProjectName(String project) {
  if (project.length <= 2) {
    return project;
  }
  return project.replaceAllMapped(
    RegExp(r'^(?<first>.)(?<middle>.+)(?<last>.)$'),
    (Match match) {
      // Сигнатура replaceAllMapped — String Function(Match); namedGroup є у RegExpMatch.
      final named = match as RegExpMatch;
      final first = named.namedGroup('first')!;
      final middle = named.namedGroup('middle')!;
      final last = named.namedGroup('last')!;
      return '$first${'*' * middle.length}$last';
    },
  );
}

/// Повертає вік запису в днях відносно [reference].
int ageInDays(TaskRecord task, {DateTime? reference}) {
  final now = reference ?? DateTime(2026, 9, 20);
  return now.difference(task.deadline).inDays.abs();
}

/// Фільтрує завдання зі статусом [status].
List<TaskRecord> filterByStatus(List<TaskRecord> items, String status) {
  return items.where((t) => t.status == status).toList();
}

/// Перетворює завдання на короткі рядкові представлення.
List<String> mapToSummaries(List<TaskRecord> items) {
  return items
      .map(
        (t) =>
            '${t.title} [${t.project}] P${t.priority} '
            '${t.effortHours}г',
      )
      .toList();
}

/// Обчислює сумарну трудомісткість через fold.
double totalEffort(List<TaskRecord> items) {
  return items.fold(0.0, (sum, t) => sum + t.effortHours);
}

/// Групує завдання за назвою проєкту.
Map<String, List<TaskRecord>> groupByProject(List<TaskRecord> items) {
  return items.fold(<String, List<TaskRecord>>{}, (map, task) {
    map.putIfAbsent(task.project, () => <TaskRecord>[]).add(task);
    return map;
  });
}

/// Середня трудомісткість у кожній групі проєктів.
Map<String, double> averageEffortByProject(List<TaskRecord> items) {
  final groups = groupByProject(items);
  return {
    for (final entry in groups.entries)
      entry.key: totalEffort(entry.value) / entry.value.length,
  };
}

/// Сортує завдання за обраним [criterion] із напрямом [ascending].
List<TaskRecord> sortTasks(
  List<TaskRecord> items, {
  bool ascending = true,
  SortCriterion criterion = SortCriterion.priority,
}) {
  final copy = [...items];
  copy.sort((a, b) {
    final primary = switch (criterion) {
      SortCriterion.priority => a.priority.compareTo(b.priority),
      SortCriterion.deadline => a.deadline.compareTo(b.deadline),
    };
    if (primary != 0) {
      return ascending ? primary : -primary;
    }
    final secondary = switch (criterion) {
      SortCriterion.priority => a.deadline.compareTo(b.deadline),
      SortCriterion.deadline => a.priority.compareTo(b.priority),
    };
    return ascending ? secondary : -secondary;
  });
  return copy;
}

/// Формує текстовий звіт за списком [items].
String buildReport(
  List<TaskRecord> items, {
  int topCount = 5,
  bool ascending = false,
  String separator = ' | ',
}) {
  final buffer = StringBuffer();
  buffer.writeln('=== Звіт планувальника завдань ===');
  buffer.writeln('Усього валідних записів: ${items.length}');
  buffer.writeln('Сумарна трудомісткість: ${totalEffort(items)} год');
  buffer.writeln();

  final sorted = sortTasks(
    items,
    ascending: ascending,
    criterion: SortCriterion.priority,
  );
  final top = sorted.take(topCount);
  buffer.writeln('Топ-$topCount за пріоритетом:');
  for (final task in top) {
    buffer.writeln(
      '${task.title}$separator'
      '${task.project}$separator'
      'P${task.priority}$separator'
      '${task.status}$separator'
      '${task.effortHours}г$separator'
      'вік ${ageInDays(task)} дн.',
    );
  }

  buffer.writeln();
  buffer.writeln('Середня трудомісткість за проєктами:');
  final averages = averageEffortByProject(items);
  for (final entry in averages.entries) {
    buffer.writeln(
      '  ${maskProjectName(entry.key)}: '
      '${entry.value.toStringAsFixed(1)} год',
    );
  }
  return buffer.toString();
}
