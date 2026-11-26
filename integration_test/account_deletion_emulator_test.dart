// Real native Firebase SDK flow, restricted to LOCAL demo emulators.
// Never create or delete accounts in the owner's production Firebase project.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:air_quality_monitor/data/local/local_avatar_store.dart';
import 'package:air_quality_monitor/data/repositories/firebase_auth_repository.dart';
import 'package:air_quality_monitor/data/services/account_data_deletion.dart';
import 'package:air_quality_monitor/data/services/firestore_account_deletion.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native SDK reauth and complete account deletion use demo emulators only',
    (tester) async {
      if (!const bool.fromEnvironment('ALLOW_LOCAL_ACCOUNT_DELETION_TEST')) {
        throw StateError('Explicit local emulator opt-in required');
      }
      final docs = await getApplicationDocumentsDirectory();
      final marker = Platform.isIOS ? 'aqm_ios_test_device' : 'aqm_test_device';
      if (!await File('${docs.path}/$marker').exists()) {
        throw StateError('Isolated QA marker required');
      }
      const project = 'demo-air-quality-monitor';
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final firebase = await Firebase.initializeApp(
        name: 'aqm-local-deletion-test',
        options: const FirebaseOptions(
          // Synthetic emulator-only key: native Installations validates A + 38 chars.
          apiKey: 'A00000000000000000000000000000000000000',
          appId: '1:1234567890:ios:1234567890abcdef123456',
          messagingSenderId: '1234567890',
          projectId: project,
        ),
      );
      if (firebase.options.projectId != project) {
        throw StateError('Refuse non-demo project');
      }
      final auth = FirebaseAuth.instanceFor(app: firebase);
      await auth.useAuthEmulator(host, 9099);
      final db = FirebaseFirestore.instanceFor(app: firebase);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator(host, 8080);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Isolated local account deletion test')),
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final email = 'local-$suffix@example.test';
      const password = 'LocalEmulatorFixtureOnly!42';
      final result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = result.user!.uid;
      final profile = db.collection('users').doc(uid);
      await profile.set({
        'name': 'Local QA',
        'email': email,
        'photoUrl': null,
        'threshold': 100,
        'backgroundAlerts': false,
        'place': null,
        'theme': 0,
        'milligrams': false,
      });
      for (var start = 0; start < 405; start += 200) {
        final batch = db.batch();
        for (var i = start; i < start + 200 && i < 405; i++) {
          batch.set(profile.collection('favorites').doc('$i'), {
            'id': '$i',
            'name': 'QA',
            'latitude': 43,
            'longitude': 76,
          });
        }
        await batch.commit();
      }
      await profile.collection('devices').doc('local').set({
        'token': 'local-emulator-token',
      });
      final rest =
          'http://$host:8080/v1/projects/$project/databases/(default)/documents';
      const admin = {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      };
      for (final collection in ['notifications', 'alertClaims']) {
        final response = await http.patch(
          Uri.parse('$rest/users/$uid/$collection/server-only'),
          headers: admin,
          body: jsonEncode({
            'fields': {
              'status': {'stringValue': 'local-fixture'},
            },
          }),
        );
        expect(response.statusCode, 200);
      }
      final avatars = LocalAvatarStore(
        Directory('${docs.path}/local-deletion-fixture-$suffix'),
      );
      await avatars.save(uid, Uint8List.fromList([1, 2, 3]));
      final other = await avatars.save(
        'other-fixture',
        Uint8List.fromList([4, 5, 6]),
      );
      final repo = FirebaseAuthRepository(
        auth: auth,
        avatars: avatars,
        eraseCloudAccount: AccountDataDeletion(
          FirestoreAccountDeletion(db, auth),
        ).erase,
      );
      await expectLater(
        repo.deleteAccount(password: 'wrong-password'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        (await profile.get(const GetOptions(source: Source.server))).exists,
        isTrue,
      );
      expect(
        (await db
                .collection('accountDeletions')
                .doc(uid)
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      await repo.deleteAccount(password: password);
      expect(auth.currentUser, isNull);
      expect(await avatars.readPath(uid), isNull);
      expect(await File(other).exists(), isTrue);
      final parent = await http.get(
        Uri.parse('$rest/users/$uid'),
        headers: admin,
      );
      expect(parent.statusCode, 404);
      for (final collection in AccountDataDeletion.collections) {
        final response = await http.get(
          Uri.parse('$rest/users/$uid/$collection'),
          headers: admin,
        );
        expect(response.statusCode, 200);
        expect((jsonDecode(response.body) as Map)['documents'] ?? [], isEmpty);
      }
      final receipt = await http.get(
        Uri.parse('$rest/accountDeletions/$uid'),
        headers: admin,
      );
      expect(receipt.statusCode, 200);
      expect(
        (jsonDecode(receipt.body) as Map)['fields'].keys,
        unorderedEquals(['startedAt', 'purgeAfter']),
      );
      final accounts = await http.get(
        Uri.parse(
          'http://$host:9099/identitytoolkit.googleapis.com/v1/projects/$project/accounts:batchGet',
        ),
        headers: admin,
      );
      expect(accounts.statusCode, 200);
      expect(
        ((jsonDecode(accounts.body) as Map)['users'] as List? ?? []).any(
          (u) => u['localId'] == uid,
        ),
        isFalse,
      );
      binding.reportData = {
        'project': project,
        'localEmulatorsOnly': true,
        'nativeReauthentication': true,
        'wrongPasswordPreservedData': true,
        'favoritesDeleted': 405,
        'allFourSubcollectionsEmpty': true,
        'authAccountDeleted': true,
        'ownAvatarRemoved': true,
        'otherFixtureAvatarPreserved': true,
        'productionAccountsTouched': false,
      };
      await db.terminate();
      await firebase.delete();
    },
  );
}
