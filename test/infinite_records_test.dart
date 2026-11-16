import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality_monitor/presentation/controllers/infinite_records_controller.dart';
import 'package:air_quality_monitor/presentation/widgets/infinite_records.dart';
import 'package:air_quality_monitor/presentation/widgets/primitives.dart';

void main() {
  test(
    'One in-flight keyset request; overlapping rows deduplicate; end is finite',
    () async {
      final gate = Completer<List<int>>();
      final cursors = <int?>[];
      final c = InfiniteRecordsController<int>(
        identity: (i) => i,
        load: (after) async {
          cursors.add(after);
          if (after == null) return gate.future;
          return List.generate(
            45,
            (i) => i + 1,
          ).where((i) => i >= after).take(21).toList();
        },
      );
      addTearDown(c.dispose);
      final first = c.next();
      await c.next();
      expect(cursors, [null]);
      gate.complete(List.generate(21, (i) => i + 1));
      await first;
      expect(c.items.length, 20);
      await c.next();
      await c.next();
      expect(c.items, List.generate(45, (i) => i + 1));
      expect(c.hasMore, isFalse);
      await c.next();
      expect(cursors, [null, 20, 39]);
    },
  );
  test('Error needs explicit retry; repeated cursor stops automatic loading; disposal is safe', () async {
    var calls = 0;
    final c = InfiniteRecordsController<int>(
      identity: (i) => i,
      load: (_) async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return List.generate(21, (i) => i);
      },
    );
    addTearDown(c.dispose);
    await c.next();
    await c.next();
    expect(calls, 1);
    await c.next(retry: true);
    expect(c.items.length, 20);
    await c.next();
    expect(c.error, isNotNull);
    await c.next();
    expect(calls, 3);
    final gate = Completer<List<int>>();
    final disposed = InfiniteRecordsController<int>(
      identity: (i) => i,
      load: (_) => gate.future,
    );
    final pending = disposed.next();
    disposed.dispose();
    gate.complete([1]);
    await pending;
  });
  testWidgets(
    'Real viewport scroll loads next portions lazily without buttons or duplicates',
    (tester) async {
      final cursors = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageBody(
              children: [
                const Text('History of test records'),
                InfiniteRecords<int>(
                  identity: (i) => i,
                  load: (after) async {
                    cursors.add(after);
                    return List.generate(
                      65,
                      (i) => i + 1,
                    ).where((i) => i > (after ?? 0)).take(21).toList();
                  },
                  itemBuilder: (i) =>
                      SizedBox(height: 90, child: Text('Record $i')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(cursors, [null]);
      expect(find.text('Record 1'), findsOneWidget);
      expect(
        find.text('Record 20'),
        findsNothing,
        reason: 'Loaded rows outside viewport stay unbuilt',
      );
      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pumpAndSettle();
      }
      expect(cursors, [null, 20, 40, 60]);
      expect(find.text('Все записи загружены'), findsOneWidget);
      expect(find.text('Следующие записи'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
