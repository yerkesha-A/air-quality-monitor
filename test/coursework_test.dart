import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../coursework/week01/exercises.dart' as exercises;
import '../docs/state_examples.dart';

void main() {
  test(
    'Dart exercises handle boundaries, nulls, immutability and async errors',
    () async {
      expect([0, 59, 60, 74, 75, 89, 90, 100].map(exercises.grade), [
        'F',
        'F',
        'C',
        'C',
        'B',
        'B',
        'A',
        'A',
      ]);
      expect(() => exercises.grade(-1), throwsRangeError);
      expect(() => exercises.grade(101), throwsRangeError);
      expect(exercises.frequencies([' Dart ', null, '', 'dart', 'Flutter']), {
        'dart': 2,
        'flutter': 1,
      });
      const task = exercises.StudyTask(title: 'Dart');
      expect(task.finish().completed, isTrue);
      expect(task.completed, isFalse);
      expect(await exercises.loadTitle(() async => ' Dart '), 'Dart');
      await expectLater(
        exercises.loadTitle(() async => ' '),
        throwsFormatException,
      );
      await expectLater(
        exercises.loadTitle(() => Future.error(StateError('offline'))),
        throwsStateError,
      );
      await expectLater(
        exercises.loadTitle(
          () => Completer<String>().future,
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(
        await exercises.runningTotal(Stream.fromIterable([1, -2, 4])).toList(),
        [1, -1, 3],
      );
    },
  );

  testWidgets(
    'setState, InheritedWidget and Provider independently update and survive rebuilds',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: StateExamples()));
      await tester.tap(find.text('Изменить модель'));
      await tester.pump();
      expect(find.text('Provider: 1'), findsOneWidget);
      await tester.tap(find.text('Локальное состояние'));
      await tester.pump();
      expect(find.text('setState: 1'), findsOneWidget);
      expect(find.text('Provider: 1'), findsOneWidget);
      expect(find.text('InheritedWidget: 0'), findsOneWidget);
      await tester.tap(find.text('Обновить зависимые виджеты'));
      await tester.pump();
      expect(find.text('InheritedWidget: 1'), findsOneWidget);
      expect(find.text('setState: 1'), findsOneWidget);
      expect(find.text('Provider: 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
