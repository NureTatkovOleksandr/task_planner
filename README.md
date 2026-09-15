# task_planner

Наскрізний навчальний проєкт з дисципліни «Програмування мовою Dart»
(ХНУРЕ, кафедра ПІ). Варіант 10 — планувальник завдань.

## Структура

```
bin/           точки входу (CLI, HTTP-сервер, демо ЛР1–ЛР3)
lib/           публічний фасад
lib/src/       реалізація
test/          модульні тести
data/          JSON/CSV дані
```

Звіти до лабораторних робіт зберігаються окремо від репозиторію.

## Запуск CLI

```bash
dart pub get
dart run -- seed
dart run -- report
dart run -- fetch-remote --limit 3 -v
dart run -- import-csv data/tasks.csv -v
dart run -- --help
```

## HTTP-сервіс

```bash
dart run bin/server.dart
```

Приклади:

```bash
curl http://127.0.0.1:8080/items
curl "http://127.0.0.1:8080/items?status=todo&minPriority=4"
curl -X POST http://127.0.0.1:8080/items -H "content-type: application/json" -d "{\"title\":\"X\",\"project\":\"Y\",\"priority\":3,\"deadline\":\"2026-12-01\",\"status\":\"todo\",\"effortHours\":2}"
```

## Перевірки якості

```bash
dart analyze
dart format .
dart test
dart compile exe bin/task_planner.dart -o build/task_planner.exe
```

## Залежності

| Пакет | Призначення | Альтернативи |
|-------|-------------|--------------|
| `args` | розбір CLI | ручний `arguments` (менш зручно) |
| `path` | безпечна збірка шляхів | конкатенація рядків (крихко на Windows) |
| `http` | REST-клієнт | `dart:io HttpClient` (багатослівніше) |
| `shelf` / `shelf_router` | HTTP-сервіс | `shelf_plus`, власний `HttpServer` |
| `test` (dev) | модульні тести | — |

Пакет `test` у `dev_dependencies`, бо потрібен лише під час розробки й не входить до runtime-збірки застосунку.

## Вживання `!`, `late`, `dynamic`

- Оператор `!` — лише після перевірок (`match == null`, `tryParse != null`, `task == null`).
- `late` не використовується.
- `dynamic` не використовується явно; результат `jsonDecode` одразу приводиться через `as` / `Map.from`.
- У `maskProjectName` параметр колбека `replaceAllMapped` має тип `Match`, тому для `namedGroup` потрібне приведення до `RegExpMatch` (інакше `dart analyze` скаржиться на типи).

## Рішення ЛР1 (коротко)

- Сортування: параметр `criterion` (`priority` / `deadline`) окремо від `ascending`.
- Вік запису: поле `deadline` з CSV, не `hashCode`.
- Лічильник: `createProcessedCounter()` повертає `(increment, read)`.
- Маскування демонструється на рядку `Інфраструктура` у `bin/lab1.dart`.

## Зовнішній API

JSONPlaceholder `https://jsonplaceholder.typicode.com/todos` — відкритий REST без ключа автентифікації.

## Демо ЛР1–ЛР3

```bash
dart run bin/lab1.dart
dart run bin/lab2.dart
dart run bin/lab3.dart
```

