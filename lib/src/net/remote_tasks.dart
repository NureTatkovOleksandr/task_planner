import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';

/// Клієнт зовнішнього REST API (JSONPlaceholder todos).
class RemoteTaskClient {
  /// Створює клієнт із опційним [http.Client].
  RemoteTaskClient({http.Client? client, this.baseUrl = defaultBaseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  /// Базовий URL за замовчуванням.
  static const String defaultBaseUrl = 'https://jsonplaceholder.typicode.com';

  final http.Client _client;
  final bool _ownsClient;

  /// Базовий URL API.
  final String baseUrl;

  /// Завантажує до [limit] віддалених «todos» і перетворює на [Task].
  Future<List<Task>> fetchTodos({int limit = 5}) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/todos'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Неуспішний код відповіді: ${response.statusCode}',
          uri: Uri.parse('$baseUrl/todos'),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Очікувався JSON-масив todos');
      }
      return decoded.take(limit).map(_mapTodo).toList();
    } on SocketException {
      rethrow;
    } on http.ClientException {
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  Task _mapTodo(Object? raw) {
    final map = Map<String, Object?>.from(raw as Map);
    final title = map['title'] as String? ?? 'без назви';
    final completed = map['completed'] as bool? ?? false;
    final id = map['id'] as int? ?? 0;
    return Task(
      title,
      'Remote',
      TaskPriority.fromLevel((id % 5) + 1),
      DateTime(2026, 12, 31),
      completed ? TaskStatus.done : TaskStatus.todo,
      1.0 + (id % 8),
    );
  }

  /// Закриває клієнт, якщо він створений цим екземпляром.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
