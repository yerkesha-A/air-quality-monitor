import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:air_quality_monitor/data/local/local_avatar_store.dart';
import 'package:air_quality_monitor/data/repositories/firebase_auth_repository.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:air_quality_monitor/presentation/providers/auth_controller.dart';
import 'package:air_quality_monitor/presentation/screens/account_deletion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class Sdk extends Mock implements FirebaseAuth {}

class SdkUser extends Mock implements User {}

class ProviderInfo extends Mock implements UserInfo {}

UserInfo provider(String id) {
  final info = ProviderInfo();
  when(() => info.providerId).thenReturn(id);
  return info;
}

class Credential extends Mock implements UserCredential {}

class AdditionalInfo extends Mock implements AdditionalUserInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      EmailAuthProvider.credential(
        email: 'fixture@example.test',
        password: 'test',
      ),
    );
    registerFallbackValue(AppleAuthProvider());
  });
  late Sdk sdk;
  late SdkUser user;
  late List<String> events;
  setUp(() {
    sdk = Sdk();
    user = SdkUser();
    events = [];
    when(() => sdk.currentUser).thenReturn(user);
    when(() => sdk.userChanges()).thenAnswer((_) => Stream.value(user));
    when(() => user.uid).thenReturn('isolated-account');
    when(() => user.email).thenReturn('fixture@example.test');
    when(() => user.displayName).thenReturn('Fixture');
    when(() => user.photoURL).thenReturn(null);
    final passwordProvider = provider('password');
    when(() => user.providerData).thenReturn([passwordProvider]);
    when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async {
      events.add('reauth');
      return Credential();
    });
    when(() => user.getIdToken(true)).thenAnswer((_) async {
      events.add('refresh');
      return 'fake-local-token';
    });
    when(() => user.delete()).thenAnswer((_) async {
      events.add('delete-auth');
    });
  });
  FirebaseAuthRepository repository({
    bool failCloud = false,
    LocalAvatarStore? avatars,
  }) => FirebaseAuthRepository(
    auth: sdk,
    avatars: avatars,
    eraseCloudAccount: (uid) async {
      expect(uid, 'isolated-account');
      events.add('erase-cloud');
      if (failCloud) throw StateError('offline');
    },
  );
  test('Password reauthentication precedes cloud and Auth deletion', () async {
    await repository().deleteAccount(password: 'test-password');
    expect(events, ['reauth', 'refresh', 'erase-cloud', 'delete-auth']);
  });
  test(
    'Wrong password, missing password and changed account never delete data',
    () async {
      await expectLater(
        repository().deleteAccount(),
        throwsA(isA<AuthFailure>()),
      );
      expect(events, isEmpty);
      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      await expectLater(
        repository().deleteAccount(password: 'wrong'),
        throwsA(isA<AuthFailure>()),
      );
      expect(events, isEmpty);
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async {
            when(() => sdk.currentUser).thenReturn(null);
            return Credential();
          });
      await expectLater(
        repository().deleteAccount(password: 'test'),
        throwsA(isA<AuthFailure>()),
      );
      expect(events, isEmpty);
    },
  );
  test(
    'Cloud error never deletes Auth or local avatar and is retryable',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aq-deletion-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final avatars = LocalAvatarStore(directory);
      final file = await avatars.save(
        'isolated-account',
        Uint8List.fromList([1, 2, 3]),
      );
      await expectLater(
        repository(
          failCloud: true,
          avatars: avatars,
        ).deleteAccount(password: 'test'),
        throwsA(isA<AuthFailure>()),
      );
      expect(await File(file).exists(), isTrue);
      verifyNever(() => user.delete());
      await repository(avatars: avatars).deleteAccount(password: 'test');
      expect(await avatars.readPath('isolated-account'), isNull);
    },
  );
  test('Linked Apple identity requires reauthorization and revocation before Auth deletion', () async {
    final info = AdditionalInfo();
    final credential = Credential();
    when(() => info.authorizationCode).thenReturn('fake-single-use-apple-code');
    when(() => credential.additionalUserInfo).thenReturn(info);
    final providers = [provider('password'), provider('apple.com')];
    when(() => user.providerData).thenReturn(providers);
    when(() => user.reauthenticateWithProvider(any())).thenAnswer((_) async {
      events.add('apple-reauth');
      return credential;
    });
    when(() => sdk.revokeTokenWithAuthorizationCode(any()))
        .thenAnswer((_) async {
          events.add('apple-revoke');
        });
    final repo = FirebaseAuthRepository(
      auth: sdk,
      appleEnabled: true,
      eraseCloudAccount: (_) async {
        events.add('erase-cloud');
      },
    );
    await repo.deleteAccount();
    expect(events, [
      'apple-reauth',
      'refresh',
      'erase-cloud',
      'apple-revoke',
      'delete-auth',
    ]);
    verifyNever(() => user.reauthenticateWithCredential(any()));
    when(() => info.authorizationCode).thenReturn(null);
    events.clear();
    await expectLater(repo.deleteAccount(), throwsA(isA<AuthFailure>()));
    expect(events, ['apple-reauth']);
  });
  test(
    'Apple sign-in uses native Firebase provider only when enabled',
    () async {
      final repo = FirebaseAuthRepository(auth: sdk);
      expect(repo.appleConfigured, isFalse);
      await expectLater(repo.apple(), throwsA(isA<AuthFailure>()));
      when(() => sdk.signInWithProvider(any()))
          .thenAnswer((_) async => Credential());
      await FirebaseAuthRepository(auth: sdk, appleEnabled: true).apple();
      verify(() => sdk.signInWithProvider(any())).called(1);
    },
  );
  testWidgets('Opening and cancelling confirmation cannot delete an account', (
    tester,
  ) async {
    final auth = AuthController(repository());
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: AccountDeletionScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Удалить мой аккаунт'));
    await tester.tap(find.text('Удалить мой аккаунт'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Подтвердить удаление'),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
