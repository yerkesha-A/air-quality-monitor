import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('RESET_TEST_EMAIL');
  const password = String.fromEnvironment('RESET_TEST_PASSWORD');
  testWidgets(
    'Separate email/password account and real reset request preserve owner session',
    (tester) async {
      await Firebase.initializeApp();
      final owner = FirebaseAuth.instance.currentUser?.uid;
      expect(owner, isNotNull);
      final app = await Firebase.initializeApp(
        name: 'password-reset-test',
        options: Firebase.app().options,
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      try {
        try {
          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        final uid = auth.currentUser!.uid;
        expect(uid, isNot(owner));
        await auth.signOut();
        await auth.signInWithEmailAndPassword(email: email, password: password);
        expect(auth.currentUser!.uid, uid);
        await auth.sendPasswordResetEmail(email: email);
        await auth.signOut();
        expect(FirebaseAuth.instance.currentUser?.uid, owner);
        await File(
          '${(await getApplicationDocumentsDirectory()).path}/secondary-reset-verification.json',
        ).writeAsString(
          jsonEncode({'requestAccepted': true, 'ownerSessionPreserved': true}),
          flush: true,
        );
      } finally {
        await auth.signOut();
        await app.delete();
      }
    },
    skip: email.isEmpty,
  );
}
