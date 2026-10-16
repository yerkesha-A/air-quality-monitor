// Дополнено 16.10.2026 при подготовке РК1. Учебные данные, не источник AQI приложения.
import 'dart:async';

/// 1. Условия и функции: оценка балла, включая проверку границ.
String grade(int score) {
  if (score < 0 || score > 100) throw RangeError.range(score, 0, 100);
  return switch (score) {
    >= 90 => 'A',
    >= 75 => 'B',
    >= 60 => 'C',
    _ => 'F',
  };
}

/// 2. Коллекции, null safety и циклы: частоты непустых слов без учёта регистра.
Map<String, int> frequencies(Iterable<String?> words) {
  final result = <String, int>{};
  for (final word in words) {
    final normalized = word?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) continue;
    result.update(normalized, (count) => count + 1, ifAbsent: () => 1);
  }
  return result;
}

/// 3. ООП: неизменяемая сущность, именованный конструктор, getter и override.
class StudyTask {
  const StudyTask({required this.title, this.completed = false});
  const StudyTask.done(String title) : this(title: title, completed: true);
  final String title;
  final bool completed;
  String get label => '${completed ? "✓" : "○"} $title';
  StudyTask finish() => StudyTask.done(title);
  @override
  String toString() => label;
}

/// 4. Future, DI и исключения: источник внедряется, timeout не скрывается.
Future<String> loadTitle(
  Future<String> Function() source, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final title = (await source().timeout(timeout)).trim();
  if (title.isEmpty) throw const FormatException('Пустой заголовок');
  return title;
}

/// 5. Stream и async*: последовательная обработка событий.
Stream<int> runningTotal(Stream<int> values) async* {
  var sum = 0;
  await for (final value in values) {
    sum += value;
    yield sum;
  }
}

Future<void> main() async {
  final report = {
    'grade': grade(95),
    'words': frequencies(['Dart', null, 'dart', 'Flutter', ' ']),
    'task': const StudyTask(title: 'Изучить Dart').finish().label,
    'future': await loadTitle(() async => ' Flutter '),
    'stream': await runningTotal(Stream.fromIterable([1, 2, 3])).toList(),
  };
  // ignore: avoid_print
  print(report);
}
