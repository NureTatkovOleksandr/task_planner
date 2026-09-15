import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:task_planner/task_planner.dart';
import 'package:test/test.dart';

void main() {
  group('сериалізація Task', () {
    test('toJson/fromJson зберігає поля', () {
      final task = taskFromParts(
        title: 'A',
        project: 'B',
        priority: 3,
        deadline: '2026-10-01',
        status: 'todo',
        effortHours: 4,
      );
      final restored = Task.fromJson(task.toJson());
      expect(restored, equals(task));
    });

    test('fromJson кидає на відсутнє поле', () {
      expect(() => Task.fromJson({'title': 'x'}), throwsA(anything));
    });
  });

  group('JsonTaskStore', () {
    test('save і load через тимчасовий файл', () async {
      final dir = await Directory.systemTemp.createTemp('tp_');
      final path = '${dir.path}/tasks.json';
      final store = JsonTaskStore(path);
      final task = Task.placeholder();
      await store.save([task]);
      final loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.title, task.title);
      await dir.delete(recursive: true);
    });
  });

  group('Repository', () {
    test('add/findById/remove', () {
      final repo = Repository<Task>();
      final task = Task.placeholder();
      repo.add(task);
      expect(repo.findById(task.id), equals(task));
      expect(repo.remove(task.id), isTrue);
      expect(repo.findById(task.id), isNull);
    });
  });

  group('CLI runApp', () {
    test('help повертає код 0', () async {
      expect(await runApp(['--help']), 0);
    });

    test('невідомі аргументи дають код 64', () async {
      expect(await runApp(['--unknown-flag']), 64);
    });
  });

  group('HTTP API', () {
    late Repository<Task> repo;
    late Handler handler;
    late Task sample;

    setUp(() {
      Task.clearCache();
      repo = Repository<Task>();
      sample = taskFromParts(
        title: 'API Task',
        project: 'API',
        priority: 4,
        deadline: '2026-10-10',
        status: 'todo',
        effortHours: 5,
      );
      repo.add(sample);
      handler = buildTaskHandler(repo);
    });

    test('GET /items повертає список', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items')),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, isNotEmpty);
    });

    test('GET /items фільтрує за status', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items?status=todo')),
      );
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body.every((e) => (e as Map)['status'] == 'todo'), isTrue);
    });

    test('GET /items/<id> повертає 404', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items/missing')),
      );
      expect(response.statusCode, 404);
    });

    test('GET /items/<id> повертає сутність', () async {
      final id = Uri.encodeComponent(sample.id);
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items/$id')),
      );
      expect(response.statusCode, 200);
    });

    test('POST /items створює сутність', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/items'),
          body: jsonEncode({
            'title': 'New',
            'project': 'P',
            'priority': 2,
            'deadline': '2026-11-01',
            'status': 'todo',
            'effortHours': 3,
          }),
        ),
      );
      expect(response.statusCode, 201);
      expect(repo.length, 2);
    });

    test('POST /items повертає 400 на некоректне тіло', () async {
      final response = await handler(
        Request('POST', Uri.parse('http://localhost/items'), body: '[]'),
      );
      expect(response.statusCode, 400);
    });
  });

  group('RemoteTaskClient', () {
    test('fetchTodos з підміненим http.Client', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'title': 'remote one', 'completed': false},
            {'id': 2, 'title': 'remote two', 'completed': true},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = RemoteTaskClient(client: mock);
      final tasks = await client.fetchTodos(limit: 2);
      expect(tasks, hasLength(2));
      expect(tasks.first.title, 'remote one');
      client.close();
    });

    test('не-2xx відповідь дає HttpException', () async {
      final mock = MockClient((request) async {
        return http.Response('nope', 500);
      });
      final client = RemoteTaskClient(client: mock);
      await expectLater(client.fetchTodos(), throwsA(isA<HttpException>()));
      client.close();
    });
  });
}
