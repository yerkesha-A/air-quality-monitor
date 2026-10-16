import 'package:air_quality_monitor/data/services/cloud_sync.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_dependencies.dart' show fixturePlace;

class MemoryCloud implements CloudSyncGateway {
  final events = <String>[];
  final places = <String, Place>{fixturePlace.id: fixturePlace};
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<CloudSnapshot> read(String uid) async {
    events.add('read:$uid');
    if (failRead) throw StateError('Server unavailable');
    return CloudSnapshot(
      settings: {'threshold': 150},
      favorites: places.values.toList(),
    );
  }

  @override
  Future<void> write(
    String uid,
    Map<String, dynamic> settings,
    List<Place> favorites,
    Set<String> removedIds,
  ) async {
    events.add('write:$uid');
    if (failWrite) throw StateError('Upload failed');
    for (final id in removedIds) {
      places.remove(id);
    }
    for (final place in favorites) {
      places[place.id] = place;
    }
  }
}

void main() {
  late MemoryCloud gateway;
  late CloudSync sync;
  late List<Place> local;
  late Set<String> removed;
  var current = true;
  Future<bool> run({Future<void> Function(CloudSnapshot)? restore}) =>
      sync.sync(
        uid: 'account',
        isCurrentAccount: () => current,
        restore:
            restore ??
            (snapshot) async {
              gateway.events.add('restore');
              local = [
                ...local,
                ...snapshot.favorites.where((p) => !removed.contains(p.id)),
              ];
            },
        settings: () async => {'threshold': 150},
        favorites: () async => local,
        removals: () async => {...removed},
        acknowledge: (sent) async => removed.removeAll(sent),
      );
  setUp(() {
    gateway = MemoryCloud();
    sync = CloudSync(gateway);
    local = [];
    removed = {};
    current = true;
  });
  test('Empty new device restores cloud before its first upload', () async {
    expect(await run(), isTrue);
    expect(gateway.events, ['read:account', 'restore', 'write:account']);
    expect(local.single.id, fixturePlace.id);
    expect(gateway.places, isNotEmpty);
  });
  test(
    'Empty local list never implies deletion, even after hydration',
    () async {
      await run();
      local.clear();
      await run();
      expect(gateway.places, isNotEmpty);
      expect(gateway.events.where((e) => e == 'read:account').length, 1);
    },
  );
  test('Failed server restore blocks all writes and can be retried', () async {
    gateway.failRead = true;
    await expectLater(run(), throwsStateError);
    expect(gateway.events, ['read:account']);
    gateway.failRead = false;
    await run();
    expect(local, isNotEmpty);
  });
  test(
    'Only explicit removals delete, failed upload keeps pending removals',
    () async {
      removed.add(fixturePlace.id);
      gateway.failWrite = true;
      await expectLater(run(), throwsStateError);
      expect(removed, contains(fixturePlace.id));
      gateway.failWrite = false;
      await run();
      expect(gateway.places, isEmpty);
      expect(removed, isEmpty);
    },
  );
  test(
    'Account change during restore blocks upload and reset rehydrates',
    () async {
      await run(
        restore: (_) async {
          current = false;
        },
      );
      expect(gateway.events, ['read:account']);
      current = true;
      sync.reset();
      await run();
      expect(gateway.events.last, 'write:account');
      expect(local, isNotEmpty);
    },
  );
}
