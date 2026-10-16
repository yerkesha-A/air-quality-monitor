import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';

/// Bounded coordinate sampling of a model grid, never street sensor readings.
class MapAirController extends ChangeNotifier {
  MapAirController(
    this.repository, {
    this.debounce = const Duration(milliseconds: 800),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final AirRepository repository;
  final Duration debounce;
  final DateTime Function() clock;
  final _cache = <String, AirReport>{};
  final _retryAt = <String, DateTime>{};
  Timer? _timer;
  Future<void> _work = Future.value();
  int _revision = 0;
  bool _disposed = false;
  bool loading = false;
  String? error;
  List<AirReport> reports = [];
  static const maxPoints = 5;
  static const maxCacheEntries = 40;

  static Place point(double latitude, double longitude) {
    // Snap to ~5 km: CAMS is a regional model, not street resolution.
    final lat = ((latitude.clamp(-89.95, 89.95) * 20).round() / 20).clamp(
      -89.95,
      89.95,
    );
    final lon = ((longitude * 20).round() / 20 + 180) % 360 - 180;
    return Place(
      id: 'map:${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
      name: 'Модельная точка',
      latitude: lat.toDouble(),
      longitude: lon,
      region: '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}',
    );
  }

  void schedule(double latitude, double longitude) {
    _timer?.cancel();
    final revision = ++_revision;
    _timer = Timer(debounce, () => _load(latitude, longitude, revision));
  }

  Future<void> refresh(double latitude, double longitude) {
    _timer?.cancel();
    return _load(latitude, longitude, ++_revision, force: true);
  }

  Future<AirReport?> select(
    double latitude,
    double longitude, {
    bool force = false,
  }) async {
    _timer?.cancel();
    final revision = ++_revision;
    await _load(latitude, longitude, revision, force: force);
    return _active(revision) && reports.isNotEmpty ? reports.first : null;
  }

  bool _active(int revision) => !_disposed && revision == _revision;
  bool _fresh(AirReport report) =>
      !report.offline &&
      !report.isStale(clock().toUtc()) &&
      clock().difference(report.fetchedAt) < const Duration(minutes: 10);

  Future<void> _load(
    double lat,
    double lon,
    int revision, {
    bool force = false,
  }) {
    _work = _work.then((_) async {
      if (_active(revision)) await _sample(lat, lon, revision, force: force);
    });
    return _work;
  }

  Future<void> _sample(
    double lat,
    double lon,
    int revision, {
    bool force = false,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    final points = [
      point(lat, lon),
      point(lat + .1, lon),
      point(lat - .1, lon),
      point(lat, lon + .1),
      point(lat, lon - .1),
    ];
    final next = <AirReport>[];
    var failures = 0;
    for (final place in {
      for (final p in points) p.id: p,
    }.values.take(maxPoints)) {
      if (!_active(revision)) return;
      try {
        var report = _cache.remove(place.id);
        report ??= await repository.cached(place);
        if (!_active(revision)) return;
        final backedOff = _retryAt[place.id]?.isAfter(clock()) == true;
        if (report == null && backedOff && !force) {
          throw const AirFailure('Источник временно недоступен');
        }
        if (force || report == null || (!_fresh(report) && !backedOff)) {
          report = await repository.fetch(place);
        }
        if (!_active(revision)) return;
        if (report.offline) {
          _retryAt[place.id] = clock().add(const Duration(minutes: 2));
        } else {
          _retryAt.remove(place.id);
        }
        _cache[place.id] = report;
        while (_cache.length > maxCacheEntries) {
          _retryAt.remove(_cache.keys.first);
          _cache.remove(_cache.keys.first);
        }
        next.add(report);
      } catch (_) {
        _retryAt[place.id] = clock().add(const Duration(minutes: 2));
        if (_retryAt.length > maxCacheEntries) {
          _retryAt.remove(_retryAt.keys.first);
        }
        failures++;
      }
    }
    if (!_active(revision)) return;
    reports = next;
    loading = false;
    error = next.isEmpty
        ? 'Нет данных для этой области. Повторите позже.'
        : failures > 0
        ? 'Для части точек данные недоступны.'
        : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _timer?.cancel();
    super.dispose();
  }
}
