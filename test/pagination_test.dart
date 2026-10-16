import 'package:air_quality_monitor/presentation/widgets/paged_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Keyset next/back, duplicate boundaries, final page and retry', (
    tester,
  ) async {
    final requested = <int?>[];
    var fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PagedRecords<int>(
              load: (after) async {
                requested.add(after);
                if (fail) throw StateError('Read failed');
                return List.generate(
                  45,
                  (i) => i + 1,
                ).where((id) => id > (after ?? 0)).take(21).toList();
              },
              itemBuilder: (id) => Text('Record $id'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить записи.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Record 20'), findsOneWidget);
    expect(find.text('Record 21'), findsNothing);
    await tester.ensureVisible(find.text('Следующие записи'));
    await tester.tap(find.text('Следующие записи'));
    await tester.pumpAndSettle();
    expect(find.text('Record 21'), findsOneWidget);
    expect(find.text('Record 40'), findsOneWidget);
    await tester.ensureVisible(find.text('Следующие записи'));
    await tester.tap(find.text('Следующие записи'));
    await tester.pumpAndSettle();
    expect(find.text('Record 45'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Следующие записи'),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Назад к записям'));
    await tester.tap(find.text('Назад к записям'));
    await tester.pumpAndSettle();
    expect(find.text('Record 21'), findsOneWidget);
    expect(requested, [null, null, 20, 40, 20]);
    expect(tester.takeException(), isNull);
  });
}
