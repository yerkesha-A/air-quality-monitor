import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/air_quality.dart';
import '../models/air_dto.dart';

class LocalStore {
  LocalStore(this.database);
  final Database database;
  static Future<LocalStore> open() async {
    final db = await openDatabase(
      path.join(await getDatabasesPath(), 'air_quality.db'),
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE alerts (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, created INTEGER NOT NULL, source TEXT NOT NULL)',
          );
        }
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE alerts (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, created INTEGER NOT NULL, source TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE cache (id TEXT PRIMARY KEY, place TEXT NOT NULL, payload TEXT NOT NULL, fetched INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE places (id TEXT PRIMARY KEY, place TEXT NOT NULL, favorite INTEGER NOT NULL DEFAULT 0, viewed INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE samples (place_id TEXT NOT NULL, hour INTEGER NOT NULL, time INTEGER NOT NULL, data TEXT NOT NULL, PRIMARY KEY(place_id, hour))',
        );
        await db.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, place_id TEXT NOT NULL, text TEXT NOT NULL, image TEXT, created INTEGER NOT NULL)',
        );
      },
    );
    return LocalStore(db);
  }

  Future<void> save(Place place, AirPayloadDto dto, DateTime fetched) async {
    final report = dto.toEntity(place, fetched);
    await database.transaction((tx) async {
      await tx.insert('cache', {
        'id': place.id,
        'place': jsonEncode(PlaceDto.fromEntity(place).toJson()),
        'payload': jsonEncode(dto.toJson()),
        'fetched': fetched.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      // Save only the current model estimate; forecasts never become observations.
      if (report != null) {
        final sample = report.current;
        await tx.insert('samples', {
          'place_id': place.id,
          'hour': sample.time.millisecondsSinceEpoch ~/ 3600000,
          'time': sample.time.millisecondsSinceEpoch,
          'data': jsonEncode(sample.values),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await tx.delete(
        'samples',
        where: 'time < ?',
        whereArgs: [
          fetched.subtract(const Duration(days: 31)).millisecondsSinceEpoch,
        ],
      );
    });
  }

  Future<AirReport?> cached(Place place) async {
    final rows = await database.query(
      'cache',
      where: 'id = ?',
      whereArgs: [place.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.first;
      return AirPayloadDto.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      ).toEntity(
        place,
        DateTime.fromMillisecondsSinceEpoch(row['fetched'] as int, isUtc: true),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> remember(Place place) async {
    final existing = await database.query(
      'places',
      where: 'id = ?',
      whereArgs: [place.id],
    );
    await database.insert('places', {
      'id': place.id,
      'place': jsonEncode(PlaceDto.fromEntity(place).toJson()),
      'favorite': existing.isEmpty ? 0 : existing.first['favorite'],
      'viewed': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Place>> places({bool favoritesOnly = false}) async {
    final rows = await database.query(
      'places',
      where: favoritesOnly ? 'favorite = 1' : null,
      orderBy: 'viewed DESC',
      limit: favoritesOnly ? null : 20,
    );
    return rows
        .map(
          (row) => PlaceDto.fromJson(
            jsonDecode(row['place'] as String) as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList();
  }

  Future<void> favorite(Place place, bool value) async {
    await remember(place);
    await database.update(
      'places',
      {'favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  Future<List<AirPoint>> history(Place place, int days) async {
    final rows = await database.query(
      'samples',
      where: 'place_id = ? AND time >= ?',
      whereArgs: [
        place.id,
        DateTime.now()
            .toUtc()
            .subtract(Duration(days: days))
            .millisecondsSinceEpoch,
      ],
      orderBy: 'time ASC',
    );
    return rows
        .map(
          (row) => AirPoint(
            time: DateTime.fromMillisecondsSinceEpoch(
              row['time'] as int,
              isUtc: true,
            ),
            values: (jsonDecode(row['data'] as String) as Map<String, dynamic>)
                .map(
                  (key, value) => MapEntry(key, (value as num?)?.toDouble()),
                ),
          ),
        )
        .toList();
  }

  Future<int> addNote(Place place, String text, String? image) =>
      database.insert('notes', {
        'place_id': place.id,
        'text': text,
        'image': image,
        'created': DateTime.now().millisecondsSinceEpoch,
      });
  Future<List<Map<String, Object?>>> notes(Place place) => database.query(
    'notes',
    where: 'place_id = ?',
    whereArgs: [place.id],
    orderBy: 'created DESC',
    limit: 50,
  );
  Future<void> deleteNote(int id) =>
      database.delete('notes', where: 'id = ?', whereArgs: [id]);
  Future<void> recordAlert({
    required String id,
    required String title,
    required String body,
    required String source,
  }) async {
    await database.insert('alerts', {
      'id': id,
      'title': title,
      'body': body,
      'created': DateTime.now().millisecondsSinceEpoch,
      'source': source,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, Object?>>> alerts() =>
      database.query('alerts', orderBy: 'created DESC', limit: 100);
}
