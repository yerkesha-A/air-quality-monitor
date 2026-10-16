import '../../domain/entities/air_quality.dart';

class CloudSnapshot {
  const CloudSnapshot({this.settings, this.favorites = const []});
  final Map<String, dynamic>? settings;
  final List<Place> favorites;
}

/// Transport boundary: tests exercise ordering without pretending to contact Firebase.
abstract interface class CloudSyncGateway {
  Future<CloudSnapshot> read(String uid);
  Future<void> write(
    String uid,
    Map<String, dynamic> settings,
    List<Place> favorites,
    Set<String> removedIds,
  );
}

class CloudSync {
  CloudSync(this.gateway);
  final CloudSyncGateway gateway;
  String? _restoredUid;
  int _session = 0;
  bool _running = false;

  void reset() {
    _session++;
    _restoredUid = null;
  }

  Future<bool> sync({
    required String uid,
    required bool Function() isCurrentAccount,
    required Future<void> Function(CloudSnapshot) restore,
    required Future<Map<String, dynamic>> Function() settings,
    required Future<List<Place>> Function() favorites,
    required Future<Set<String>> Function() removals,
    required Future<void> Function(Set<String>) acknowledge,
  }) async {
    if (_running) return false;
    _running = true;
    final session = _session;
    bool active() => session == _session && isCurrentAccount();
    try {
      if (!active()) return false;
      if (_restoredUid != uid) {
        // A failed server read must never fall through to an upload.
        final cloud = await gateway.read(uid);
        if (!active()) return false;
        await restore(cloud);
        if (!active()) return false;
        _restoredUid = uid;
      }
      final removed = await removals();
      final data = await settings();
      final places = await favorites();
      if (!active()) return false;
      await gateway.write(uid, data, places, removed);
      if (active()) await acknowledge(removed);
      return true;
    } finally {
      _running = false;
    }
  }
}
