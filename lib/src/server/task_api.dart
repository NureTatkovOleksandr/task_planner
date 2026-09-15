import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/repository.dart';
import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';

/// Будує маршрутизатор HTTP API для сховища [repo].
Router buildTaskRouter(Repository<Task> repo) {
  final router = Router();

  router.get('/items', (Request request) async {
    final status = request.url.queryParameters['status'];
    final minPriority = int.tryParse(
      request.url.queryParameters['minPriority'] ?? '',
    );
    var items = repo.all;
    if (status != null) {
      items = items.where((t) => t.status.code == status);
    }
    if (minPriority != null) {
      items = items.where((t) => t.priority.level >= minPriority);
    }
    return Response.ok(
      jsonEncode(items.map((e) => e.toJson()).toList()),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.get('/items/<id>', (Request request, String id) async {
    final decodedId = Uri.decodeComponent(id);
    final item = repo.findById(decodedId);
    if (item == null) {
      return Response.notFound(
        jsonEncode({'error': 'not_found', 'id': decodedId}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return Response.ok(
      jsonEncode(item.toJson()),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.post('/items', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return Response.badRequest(
          body: jsonEncode({'error': 'body_must_be_object'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      final task = Task.fromJson(Map<String, Object?>.from(decoded));
      repo.add(task);
      return Response(
        201,
        body: jsonEncode(task.toJson()),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'invalid_body', 'message': e.message}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on TypeError catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'invalid_body', 'message': '$e'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'invalid_body', 'message': e.message}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  });

  return router;
}

/// Проміжний обробник журналювання запитів.
Middleware requestLogMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final started = DateTime.now();
      final response = await inner(request);
      final ms = DateTime.now().difference(started).inMilliseconds;
      print(
        '${request.method} ${request.requestedUri.path} '
        '-> ${response.statusCode} (${ms}ms)',
      );
      return response;
    };
  };
}

/// Збирає повний [Handler] API.
Handler buildTaskHandler(Repository<Task> repo) {
  final router = buildTaskRouter(repo);
  return Pipeline()
      .addMiddleware(requestLogMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);
}

/// Парсить тіло завдання для тестів і повторного використання.
Task? tryParseTaskBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return null;
    }
    return Task.fromJson(Map<String, Object?>.from(decoded));
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// Допоміжне створення завдання з мінімальних полів.
Task taskFromParts({
  required String title,
  required String project,
  required int priority,
  required String deadline,
  required String status,
  required double effortHours,
}) {
  return Task(
    title,
    project,
    TaskPriority.fromLevel(priority),
    DateTime.parse(deadline),
    TaskStatus.tryParse(status)!,
    effortHours,
  );
}
