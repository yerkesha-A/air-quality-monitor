import 'dart:async';
import 'dart:io';

import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('FIREBASE_TEST_EMAIL');
  const password = String.fromEnvironment('FIREBASE_TEST_PASSWORD');
  testWidgets('Real FCM foreground delivery on Android', (tester) async {
    final deps = await AppDependencies.create(
      await SharedPreferences.getInstance(),
    );
    expect(
      FirebaseAuth.instance.currentUser,
      isNull,
      reason: 'Do not replace an existing session',
    );
    final delivered = Completer<void>();
    final subscription = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['verification'] == 'stage2-android' &&
          !delivered.isCompleted) {
        delivered.complete();
      }
    });
    File? tokenFile;
    try {
      await deps.auth.login(email, password);
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseMessaging.instance.deleteToken();
      expect(
        await deps.firebase.enablePush(Account(id: user.uid, email: email)),
        isTrue,
      );
      final token = await FirebaseMessaging.instance.getToken();
      expect(token, isNotNull);
      tokenFile = File(
        '${(await getApplicationDocumentsDirectory()).path}/stage2-fcm-token',
      );
      await tokenFile.writeAsString(token!, flush: true);
      // The private admin helper sends a real HTTP v1 push during this window.
      await tester.runAsync(
        () => delivered.future.timeout(const Duration(seconds: 120)),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          final alerts = await deps.store.alertsPage();
          if (alerts.any((row) => row['title'] == 'Проверка Firebase')) return;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        fail('Received push was not recorded in local history');
      });
    } finally {
      if (tokenFile != null && await tokenFile.exists()) {
        await tokenFile.delete();
      }
      await subscription.cancel();
      await deps.firebase.unregisterDevice();
      await deps.auth.logout();
      await deps.firebase.dispose();
      await deps.store.database.close();
    }
  }, skip: email.isEmpty);
}
