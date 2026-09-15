import 'package:task_planner/task_planner.dart';
import 'package:test/test.dart';

void main() {
  test('parseLine розбирає коректний рядок', () {
    final outcome = parseLine('Тест;Проєкт;3;2026-09-15;todo;4');
    expect(outcome.error, isNull);
    expect(outcome.task?.title, 'Тест');
    expect(outcome.task?.priority, 3);
  });

  test('parseLine відхиляє пошкоджений рядок', () {
    final outcome = parseLine('Замало полів;A;1');
    expect(outcome.task, isNull);
    expect(outcome.error, isNotNull);
  });
}
