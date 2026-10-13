import 'dart:async';

import 'package:air_quality_monitor/data/repositories/firebase_auth_repository.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:air_quality_monitor/presentation/providers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// SDK mocks only: these tests do not create accounts or contact Firebase.
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'Missing native Firebase/Google configuration stays explicitly unavailable',
    () async {
      final repo = FirebaseAuthRepository();
      expect(repo.configured, isFalse);
      expect(repo.googleConfigured, isFalse);
      expect(await repo.changes.first, isNull);
      await expectLater(
        repo.login('person@example.test', 'password'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(repo.google(), throwsA(isA<AuthFailure>()));
    },
  );
  test(
    'Email login, registration, reset and logout call the actual SDK methods',
    () async {
      final sdk = MockFirebaseAuth();
      final result = MockUserCredential();
      final user = MockUser();
      when(() => result.user).thenReturn(user);
      when(
        () => sdk.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => result);
      when(
        () => sdk.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => result);
      when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => sdk.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});
      when(() => sdk.signOut()).thenAnswer((_) async {});
      final repo = FirebaseAuthRepository(auth: sdk);
      await repo.login('person@example.test', 'a-password');
      await repo.register('person@example.test', 'a-password', 'Имя');
      await repo.reset('person@example.test');
      await repo.logout();
      verify(
        () => sdk.signInWithEmailAndPassword(
          email: 'person@example.test',
          password: 'a-password',
        ),
      ).called(1);
      verify(
        () => sdk.createUserWithEmailAndPassword(
          email: 'person@example.test',
          password: 'a-password',
        ),
      ).called(1);
      verify(() => user.updateDisplayName('Имя')).called(1);
      verify(() => sdk.sendPasswordResetEmail(email: 'person@example.test'))
          .called(1);
      verify(() => sdk.signOut()).called(1);
      expect(repo.googleConfigured, isFalse);
    },
  );
  for (final entry in {
    'invalid-credential': 'Проверьте email и пароль.',
    'email-already-in-use': 'Этот email уже зарегистрирован.',
    'network-request-failed': 'Проверьте подключение к интернету.',
    'user-disabled': 'Этот аккаунт отключён. Обратитесь в поддержку.',
  }.entries) {
    test('Firebase ${entry.key} has an actionable Russian message', () async {
      final sdk = MockFirebaseAuth();
      when(
        () => sdk.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: entry.key));
      await expectLater(
        FirebaseAuthRepository(auth: sdk)
            .login('person@example.test', 'a-password'),
        throwsA(
          isA<AuthFailure>().having((e) => e.message, 'message', entry.value),
        ),
      );
    });
  }
  test('Controller receives restored SDK session, blocks duplicate requests and resets busy on failure', () async {
    final stream = StreamController<Account?>();
    final repo = MockAuthRepository();
    when(() => repo.changes).thenAnswer((_) => stream.stream);
    final pending = Completer<void>();
    when(() => repo.login(any(), any())).thenAnswer((_) => pending.future);
    final controller = AuthController(repo);
    const account = Account(id: 'test-only-id', email: 'person@example.test');
    stream.add(account);
    await Future<void>.delayed(Duration.zero);
    expect(controller.account, account);
    final first = controller.login('person@example.test', 'a-password');
    expect(controller.busy, isTrue);
    expect(
      await controller.login('person@example.test', 'a-password'),
      isFalse,
    );
    pending.completeError(const AuthFailure('Проверьте email и пароль.'));
    expect(await first, isFalse);
    expect(controller.busy, isFalse);
    expect(controller.error, 'Проверьте email и пароль.');
    verify(() => repo.login(any(), any())).called(1);
    controller.dispose();
    await stream.close();
  });
  test('Cloud cleanup failure cannot prevent logout; SDK session change clears account', () async {
    final stream = StreamController<Account?>();
    final repo = MockAuthRepository();
    when(() => repo.changes).thenAnswer((_) => stream.stream);
    when(() => repo.logout()).thenAnswer((_) async {
      stream.add(null);
    });
    final controller = AuthController(repo);
    stream.add(const Account(id: 'test-only-id', email: 'person@example.test'));
    await Future<void>.delayed(Duration.zero);
    controller.beforeLogout = () async => throw Exception('Cloud unavailable');
    expect(await controller.logout(), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.account, isNull);
    verify(() => repo.logout()).called(1);
    controller.dispose();
    await stream.close();
  });
  test('Completing a request after controller disposal does not notify a disposed provider', () async {
    final repo = MockAuthRepository();
    when(() => repo.changes).thenAnswer((_) => const Stream.empty());
    final pending = Completer<void>();
    when(() => repo.reset(any())).thenAnswer((_) => pending.future);
    final controller = AuthController(repo);
    final result = controller.reset('person@example.test');
    controller.dispose();
    pending.complete();
    expect(await result, isTrue);
  });
}
