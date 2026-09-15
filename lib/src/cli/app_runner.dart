import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../async/async_repository.dart';
import '../csv_data.dart';
import '../io/json_store.dart';
import '../io/line_reader.dart';
import '../models/task.dart';
import '../net/remote_tasks.dart';
import '../task_processing.dart';

/// Розбирає аргументи CLI та виконує команду.
Future<int> runApp(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Показати довідку')
    ..addOption(
      'data',
      abbr: 'd',
      defaultsTo: JsonTaskStore.defaultPath(),
      help: 'Шлях до JSON-файлу даних',
    )
    ..addOption(
      'limit',
      abbr: 'l',
      defaultsTo: '5',
      help: 'Ліміт віддалених записів',
    )
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Докладний вивід');

  parser.addCommand('report');
  parser.addCommand('import-csv');
  parser.addCommand('fetch-remote');
  parser.addCommand('seed');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }

  if (results['help'] as bool || results.command == null) {
    stdout.writeln('Планувальник завдань — CLI');
    stdout.writeln(parser.usage);
    stdout.writeln('Команди: report, import-csv, fetch-remote, seed');
    return 0;
  }

  final dataPath = results['data'] as String;
  final verbose = results['verbose'] as bool;
  final store = JsonTaskStore(dataPath);
  final command = results.command!;

  try {
    switch (command.name) {
      case 'seed':
        await _seedFromCsv(store, verbose: verbose);
      case 'report':
        await _report(store);
      case 'import-csv':
        final csvPath = command.rest.isEmpty
            ? p.join('data', 'tasks.csv')
            : command.rest.first;
        await _importCsv(store, csvPath, verbose: verbose);
      case 'fetch-remote':
        final limit = int.tryParse(results['limit'] as String) ?? 5;
        await _fetchRemote(store, limit: limit, verbose: verbose);
      default:
        stderr.writeln('Невідома команда: ${command.name}');
        return 64;
    }
    return 0;
  } on SocketException catch (e) {
    stderr.writeln('Немає зʼєднання: $e');
    return 1;
  } on HttpException catch (e) {
    stderr.writeln('HTTP-помилка: $e');
    return 1;
  } on FormatException catch (e) {
    stderr.writeln('Помилка формату: $e');
    return 1;
  } catch (e) {
    stderr.writeln('Неочікувана помилка: $e');
    return 1;
  }
}

Future<void> _seedFromCsv(JsonTaskStore store, {required bool verbose}) async {
  Task.clearCache();
  final tasks = <Task>[];
  for (final line in rawTaskLines) {
    try {
      final task = Task.fromCsv(line);
      final record = parseLine(line).task;
      if (record != null && validateTask(record).isEmpty) {
        tasks.add(task);
      }
    } on FormatException {
      if (verbose) {
        stderr.writeln('пропущено: $line');
      }
    }
  }
  await store.save(tasks);
  stdout.writeln('Збережено ${tasks.length} завдань у ${store.filePath}');
}

Future<void> _report(JsonTaskStore store) async {
  final tasks = await store.load();
  stdout.writeln('Завантажено: ${tasks.length}');
  for (final task in tasks.take(10)) {
    stdout.writeln('  ${task.describe()}');
  }
}

Future<void> _importCsv(
  JsonTaskStore store,
  String csvPath, {
  required bool verbose,
}) async {
  final tasks = <Task>[...await store.load()];
  await for (final line in readLines(csvPath)) {
    if (line.trim().isEmpty) {
      continue;
    }
    try {
      tasks.add(Task.fromCsv(line));
    } on FormatException catch (e) {
      if (verbose) {
        stderr.writeln(e.message);
      }
    }
  }
  await store.save(tasks);
  stdout.writeln('Імпортовано, усього: ${tasks.length}');
}

Future<void> _fetchRemote(
  JsonTaskStore store, {
  required int limit,
  required bool verbose,
}) async {
  final client = RemoteTaskClient();
  try {
    final remote = await client.fetchTodos(limit: limit);
    final tasks = [...await store.load(), ...remote];
    await store.save(tasks);
    stdout.writeln('Додано ${remote.length} віддалених завдань');
    if (verbose) {
      for (final task in remote) {
        stdout.writeln('  ${task.title}');
      }
    }
  } finally {
    client.close();
  }
}

/// Демонстраційний асинхронний шар для сумісності з ЛР3.
Future<void> demoAsyncLayer() async {
  final repo = AsyncRepository<Task>(delay: Duration.zero);
  repo.seed(Task.placeholder());
  await repo.loadAll();
}
