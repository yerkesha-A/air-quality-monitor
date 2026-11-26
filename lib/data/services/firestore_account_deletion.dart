import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'account_data_deletion.dart';

class FirestoreAccountDeletion implements AccountDataGateway {
  FirestoreAccountDeletion(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  void _check(String uid) {
    if (auth.currentUser?.uid != uid) {
      throw StateError('Account changed during deletion');
    }
  }

  @override
  Future<void> begin(String uid) async {
    _check(uid);
    // A security tombstone contains no email, name, photo or device token.
    // Keep until old Firebase ID tokens expire (up to one hour). It can be
    // removed by the administrator after purgeAfter; no paid TTL is required.
    await db.collection('accountDeletions').doc(uid).set({
      'startedAt': FieldValue.serverTimestamp(),
      'purgeAfter': Timestamp.fromDate(
        DateTime.now().toUtc().add(const Duration(hours: 2)),
      ),
    });
  }

  @override
  Future<List<String>> page(String uid, String collection, int limit) async {
    _check(uid);
    final result = await db
        .collection('users')
        .doc(uid)
        .collection(collection)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return result.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<void> remove(String uid, String collection, List<String> ids) async {
    _check(uid);
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(
        db.collection('users').doc(uid).collection(collection).doc(id),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> removeProfile(String uid) async {
    _check(uid);
    await db.collection('users').doc(uid).delete();
  }
}
