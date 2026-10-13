import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({this.auth, this.storage, this.googleClientId = ''});
  final FirebaseAuth? auth;
  final FirebaseStorage? storage;
  final String googleClientId;
  bool _googleInitialized = false;
  @override
  bool get configured => auth != null;
  @override
  bool get googleConfigured => configured && googleClientId.isNotEmpty;
  FirebaseAuth get _auth =>
      auth ??
      (throw const AuthFailure(
        'Сервис аккаунтов пока не подключён. Мониторинг доступен без входа.',
      ));
  @override
  Stream<Account?> get changes =>
      auth?.userChanges().map(
        (user) => user == null
            ? null
            : Account(
                id: user.uid,
                email: user.email ?? '',
                name: user.displayName ?? '',
                photoUrl: user.photoURL,
              ),
      ) ??
      Stream.value(null);
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Проверьте email и пароль.',
        'email-already-in-use' => 'Этот email уже зарегистрирован.',
        'user-disabled' => 'Этот аккаунт отключён. Обратитесь в поддержку.',
        'requires-recent-login' =>
          'Войдите повторно, чтобы выполнить это действие.',
        'invalid-email' => 'Введите корректный email.',
        'weak-password' => 'Выберите более надёжный пароль.',
        'too-many-requests' => 'Слишком много попыток. Подождите и повторите.',
        'network-request-failed' => 'Проверьте подключение к интернету.',
        'operation-not-allowed' => 'Этот способ входа не включён в Firebase.',
        _ => 'Не удалось выполнить действие с аккаунтом (${e.code}).',
      });
    }
  }

  @override
  Future<void> login(String email, String password) => _run(() async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  });
  @override
  Future<void> register(String email, String password, String name) =>
      _run(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.updateDisplayName(name);
      });
  @override
  Future<void> reset(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email));
  @override
  Future<void> google() => _run(() async {
    if (!googleConfigured) {
      throw const AuthFailure('Google Sign-In ещё не настроен для Android.');
    }
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: googleClientId.isEmpty ? null : googleClientId,
      );
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const AuthFailure(
        'Google не вернул токен входа. Проверьте OAuth-настройки.',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  });
  @override
  Future<void> updateName(String name) => _run(() async {
    await _auth.currentUser?.updateDisplayName(name);
    await _auth.currentUser?.reload();
  });
  @override
  Future<void> updateAvatar(Uint8List bytes) => _run(() async {
    final user = _auth.currentUser;
    if (user == null || storage == null) {
      throw const AuthFailure(
        'Войдите в аккаунт и подключите хранилище профиля.',
      );
    }
    final ref = storage!.ref('avatars/${user.uid}/profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await user.updatePhotoURL(await ref.getDownloadURL());
    await user.reload();
  });
  @override
  Future<void> logout() async {
    await _run(_auth.signOut);
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase session has already ended. */
      }
    }
  }
}
