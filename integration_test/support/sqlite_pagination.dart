import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

/// Isolated real Android SQLite; no fixture is written to the user's air history.
Future<void> verifySqlitePagination() async {
  final db = await openDatabase(inMemoryDatabasePath);
  try {
    await db.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, place_id TEXT, text TEXT, image TEXT, created INTEGER)',
    );
    await db.execute(
      'CREATE TABLE alerts (id TEXT PRIMARY KEY, title TEXT, body TEXT, created INTEGER, source TEXT)',
    );
    await db.execute(
      'CREATE TABLE samples (place_id TEXT, time INTEGER, data TEXT)',
    );
    const place = Place(
      id: 'isolated-test',
      name: 'SQLite test',
      latitude: 0,
      longitude: 0,
    );
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    final batch = db.batch();
    for (var i = 0; i < 45; i++) {
      batch.insert('notes', {
        'place_id': place.id,
        'text': 'note $i',
        'created': time,
      });
      batch.insert('alerts', {
        'id': i.toString().padLeft(3, '0'),
        'title': 'test',
        'body': '',
        'created': time,
        'source': 'test',
      });
      batch.insert('samples', {
        'place_id': place.id,
        'time': time - i * 3600000,
        'data': '{"us_aqi":42}',
      });
    }
    await batch.commit(noResult: true);
    final store = LocalStore(db);
    for (final load in [
      (Map<String, Object?>? cursor) => store.notesPage(place, after: cursor),
      (Map<String, Object?>? cursor) => store.alertsPage(after: cursor),
    ]) {
      final first = await load(null);
      expect(first.length, 21);
      final second = await load(first[19]);
      final third = await load(second[19]);
      final ids = [
        ...first.take(20),
        ...second.take(20),
        ...third,
      ].map((row) => row['id']).toList();
      expect(ids.length, 45);
      expect(
        ids.toSet().length,
        45,
        reason: 'Equal timestamps must not skip/duplicate rows',
      );
    }
    final first = await store.historyPage(place, 7);
    final second = await store.historyPage(place, 7, after: first[19]);
    final third = await store.historyPage(place, 7, after: second[19]);
    final points = [...first.take(20), ...second.take(20), ...third];
    expect(points.length, 45);
    expect(points.map((p) => p.time).toSet().length, 45);
  } finally {
    await db.close();
  }
}
