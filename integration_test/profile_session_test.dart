import 'dart:convert';
import 'dart:io';

import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/data/local/local_avatar_store.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:air_quality_monitor/presentation/screens/account_screen.dart';
import 'package:air_quality_monitor/presentation/screens/auth_screen.dart';
import 'package:air_quality_monitor/presentation/widgets/account_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// No logout, no account replacement, no writes to user settings/favorites.
// Run capture and verify as two --no-uninstall invocations, restarting in between.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const verify = bool.fromEnvironment('VERIFY_PROFILE_RESTART');
  testWidgets(
    'Google session, profile and local data survive process restart',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final deps = await AppDependencies.create(prefs);
      final user = FirebaseAuth.instance.currentUser;
      expect(
        user,
        isNotNull,
        reason: 'Requires the existing signed-in Google account',
      );
      expect(
        user!.providerData.any((p) => p.providerId == 'google.com'),
        isTrue,
      );
      if (const bool.fromEnvironment('SEND_PROFILE_RESET')) {
        await deps.auth.reset(user.email!);
      }
      final docs = await getApplicationDocumentsDirectory();
      final probeStore = LocalAvatarStore(
        Directory('${docs.path}/profile-storage-verification'),
      );
      final probeBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      );
      if (verify) {
        final savedProbe = await probeStore.readPath('storage-check');
        expect(savedProbe, isNotNull);
        expect(await File(savedProbe!).readAsBytes(), probeBytes);
      } else {
        await probeStore.save('storage-check', probeBytes);
      }
      final snapshotFile = File('${docs.path}/profile-verification.json');
      final photoStore = await LocalAvatarStore.open();
      final selected = await deps.places.selected();
      final favorites =
          (await deps.places.favorites()).map((p) => p.id).toList()..sort();
      final snapshot = <String, dynamic>{
        'uid': user.uid,
        'favorites': favorites,
        'selected': selected?.id,
        'photo': await photoStore.readPath(user.uid),
        'settings': {
          for (final key in [
            'theme',
            'threshold',
            'milligrams',
            'backgroundAlerts',
            'alerts',
            'onboarded',
          ])
            key: prefs.get(key),
        },
      };
      if (verify) {
        expect(await snapshotFile.exists(), isTrue);
        expect(snapshot, jsonDecode(await snapshotFile.readAsString()));
      } else {
        await snapshotFile.writeAsString(jsonEncode(snapshot), flush: true);
      }
      final settings = SettingsController(prefs);
      await tester.pumpWidget(
        AirQualityApp(settings: settings, dependencies: deps),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      final profileContext = tester.element(find.byType(AccountAvatar).first);
      GoRouter.of(profileContext).push('/account');
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text(user.email!), findsOneWidget);
      final avatar = find.descendant(
        of: find.byType(AccountScreen),
        matching: find.byKey(const ValueKey('account-avatar')),
      );
      expect(tester.getSize(avatar), const Size(88, 88));
      await tester.tap(find.text('Изменить фото'));
      await tester.pumpAndSettle();
      expect(find.text('Выбрать из галереи'), findsOneWidget);
      expect(find.text('Сделать снимок'), findsOneWidget);
      Navigator.of(tester.element(find.text('Сделать снимок'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsNothing);
      if (const bool.fromEnvironment('RECHECK_GOOGLE_LOGIN')) {
        final router = GoRouter.of(profileContext);
        await deps.auth.logout();
        await tester.pumpAndSettle();
        expect(FirebaseAuth.instance.currentUser, isNull);
        router.go('/account');
        await tester.pumpAndSettle();
        expect(find.byType(AuthScreen), findsOneWidget);
        final signIn = deps.auth.google();
        await tester.runAsync(
          () => signIn.timeout(const Duration(seconds: 120)),
        );
        await tester.pumpAndSettle();
        expect(FirebaseAuth.instance.currentUser?.uid, snapshot['uid']);
        expect(find.byType(AccountScreen), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      // Releasing the widget tree closes services; keep the user's session intact.
      await tester.pumpWidget(const SizedBox.shrink());
      await deps.store.database.close();
      settings.dispose();
    },
  );
}
