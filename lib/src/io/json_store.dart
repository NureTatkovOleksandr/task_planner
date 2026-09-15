import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/task.dart';

/// Зберігає та завантажує завдання у файлі JSON.
class JsonTaskStore {
  /// Створює сховище за шляхом [filePath].
  JsonTaskStore(this.filePath);

  /// Абсолютний або відносний шлях до JSON-файлу.
  final String filePath;

  /// Зберігає список [tasks] у файл.
  Future<void> save(List<Task> tasks) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final payload = tasks.map((t) => t.toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  /// Завантажує завдання з файлу; порожній список, якщо файлу немає.
  Future<List<Task>> load() async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return [];
    }
    final raw = jsonDecode(await file.readAsString());
    if (raw is! List) {
      throw const FormatException('Очікувався JSON-масив завдань');
    }
    return raw
        .map((item) => Task.fromJson(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  /// Будує шлях до файлу даних відносно [baseDir].
  static String defaultPath([String baseDir = '.']) {
    return p.join(baseDir, 'data', 'tasks.json');
  }
}
