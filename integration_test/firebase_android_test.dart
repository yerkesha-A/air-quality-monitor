import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/data/services/cloud_sync.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Opt-in real backend test. Credentials live in an ignored local define file.
// Run with --no-uninstall; never sign out an existing user's session.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('FIREBASE_TEST_EMAIL');
  const password = String.fromEnvironment('FIREBASE_TEST_PASSWORD');
  testWidgets('Real Android email auth and safe Firestore restore', (
    tester,
  ) async {
    expect(email, isNotEmpty, reason: 'Provide private test credentials');
    expect(password.length, greaterThanOrEqualTo(12));
    final deps = await AppDependencies.create(
      await SharedPreferences.getInstance(),
    );
    expect(deps.firebase.configured, isTrue);
    expect(deps.auth.googleConfigured, isTrue);
    expect(
      FirebaseAuth.instance.currentUser,
      isNull,
      reason: 'Do not replace an existing user session',
    );
    try {
      await expectLater(
        deps.auth.register(email, '123', 'Test'),
        throwsA(isA<AuthFailure>()),
      );
      await deps.auth.register(email, password, 'Android Firebase Test');
      final uid = FirebaseAuth.instance.currentUser!.uid;
      expect(FirebaseAuth.instance.currentUser!.email, email);
      await expectLater(
        deps.auth.register(email, password, 'Test'),
        throwsA(isA<AuthFailure>()),
      );
      final user = FirebaseFirestore.instance.collection('users').doc(uid);
      const place = Place(
        id: 'firebase-android-test',
        name: 'Test city',
        latitude: 43.25,
        longitude: 76.95,
        country: 'Kazakhstan',
      );
      final settings = <String, dynamic>{
        'name': 'Android Firebase Test',
        'email': email,
        'photoUrl': null,
        'threshold': 125,
        'backgroundAlerts': false,
        'place': null,
        'theme': 0,
        'milligrams': false,
      };
      await deps.firebase.cloudSync.sync(
        uid: uid,
        isCurrentAccount: () => FirebaseAuth.instance.currentUser?.uid == uid,
        restore: (_) async {},
        settings: () async => settings,
        favorites: () async => [place],
        removals: () async => {},
        acknowledge: (_) async {},
      );
      expect(
        (await user.get(const GetOptions(source: Source.server)))
            .data()?['threshold'],
        125,
      );
      await deps.auth.logout();
      expect(FirebaseAuth.instance.currentUser, isNull);
      await expectLater(
        deps.auth.login(email, '${password}wrong'),
        throwsA(isA<AuthFailure>()),
      );
      await deps.auth.login(email, password);
      expect(FirebaseAuth.instance.currentUser!.uid, uid);
      deps.firebase.cloudSync.reset();
      var restored = false;
      await deps.firebase.cloudSync.sync(
        uid: uid,
        isCurrentAccount: () => FirebaseAuth.instance.currentUser?.uid == uid,
        restore: (CloudSnapshot snapshot) async {
          expect(snapshot.favorites.map((p) => p.id), contains(place.id));
          expect(snapshot.settings?['threshold'], 125);
          restored = true;
        },
        settings: () async => settings,
        favorites: () async => [],
        removals: () async => {},
        acknowledge: (_) async {},
      );
      expect(restored, isTrue);
      expect(
        (await user
                .collection('favorites')
                .doc(place.id)
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      await expectLater(
        FirebaseFirestore.instance
            .collection('users')
            .doc('unrelated-account')
            .get(const GetOptions(source: Source.server)),
        throwsA(isA<FirebaseException>()),
      );
    } finally {
      await deps.auth.logout();
      await deps.firebase.dispose();
      await deps.store.database.close();
    }
  }, skip: email.isEmpty);
}
