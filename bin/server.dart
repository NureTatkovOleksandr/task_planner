import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:task_planner/task_planner.dart';

Future<void> main(List<String> arguments) async {
  Task.clearCache();
  final repo = Repository<Task>();
  final store = JsonTaskStore(JsonTaskStore.defaultPath());
  final tasks = await store.load();
  if (tasks.isEmpty) {
    for (final line in rawTaskLines) {
      try {
        repo.add(Task.fromCsv(line));
      } on FormatException {
        // ignore damaged
      }
    }
  } else {
    for (final task in tasks) {
      repo.add(task);
    }
  }

  final handler = buildTaskHandler(repo);
  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    8080,
  );
  print('HTTP-сервіс: http://${server.address.host}:${server.port}');
  print('Маршрути: GET /items, GET /items/<id>, POST /items');
}
