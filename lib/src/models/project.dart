import 'describable.dart';
import 'identifiable.dart';

/// Сутність проєкту — друга гілка, до якої підмішано домішки.
final class Project extends Identifiable with Describable, Timestamped {
  /// Створює проєкт із назвою [name].
  Project(this.name, {DateTime? updatedAt})
    : id = name.toLowerCase().replaceAll(' ', '-'),
      updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  final String id;

  /// Назва проєкту.
  final String name;

  @override
  final DateTime updatedAt;

  @override
  String get displayName => name;

  @override
  String toString() => 'Project($name)';
}
