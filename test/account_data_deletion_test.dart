import 'package:air_quality_monitor/data/services/account_data_deletion.dart';
import 'package:flutter_test/flutter_test.dart';

class DeletionGateway implements AccountDataGateway {
  final events = <String>[];
  final documents = {
    for (final name in AccountDataDeletion.collections)
      name: List.generate(451, (i) => '$i'),
  };
  bool failBarrier = false;
  bool failPage = false;
  bool profileExists = true;
  @override
  Future<void> begin(String uid) async {
    events.add('barrier');
    if (failBarrier) throw StateError('Rules not deployed');
  }

  @override
  Future<List<String>> page(String uid, String collection, int limit) async {
    if (failPage) throw StateError('Offline');
    return documents[collection]!.take(limit).toList();
  }

  @override
  Future<void> remove(String uid, String collection, List<String> ids) async {
    events.add('$collection:${ids.length}');
    documents[collection]!.removeWhere(ids.contains);
  }

  @override
  Future<void> removeProfile(String uid) async {
    events.add('profile');
    profileExists = false;
  }
}

void main() {
  test(
    'Barrier first, every collection paged within batch limits, profile last',
    () async {
      final gateway = DeletionGateway();
      await AccountDataDeletion(gateway).erase('test-only-user');
      expect(gateway.events.first, 'barrier');
      expect(gateway.events.last, 'profile');
      for (final collection in AccountDataDeletion.collections) {
        expect(gateway.documents[collection], isEmpty);
        expect(
          gateway.events,
          containsAllInOrder([
            '$collection:200',
            '$collection:200',
            '$collection:51',
          ]),
        );
      }
      expect(gateway.profileExists, isFalse);
    },
  );
  test('Old production rules fail closed before deleting anything', () async {
    final gateway = DeletionGateway()..failBarrier = true;
    await expectLater(
      AccountDataDeletion(gateway).erase('test-user'),
      throwsStateError,
    );
    expect(gateway.events, ['barrier']);
    expect(gateway.profileExists, isTrue);
    expect(
      gateway.documents.values.every((docs) => docs.length == 451),
      isTrue,
    );
  });
  test(
    'Interrupted deletion preserves profile and can be retried idempotently',
    () async {
      final gateway = DeletionGateway()..failPage = true;
      final deletion = AccountDataDeletion(gateway);
      await expectLater(deletion.erase('test-user'), throwsStateError);
      expect(gateway.profileExists, isTrue);
      gateway.failPage = false;
      await deletion.erase('test-user');
      await deletion.erase('test-user');
      expect(gateway.documents.values.every((docs) => docs.isEmpty), isTrue);
      expect(gateway.profileExists, isFalse);
    },
  );
}
