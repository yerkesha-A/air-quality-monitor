import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../local/local_avatar_store.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({this.auth, this.avatars, this.googleClientId = ''});
  final FirebaseAuth? auth;
  final LocalAvatarStore? avatars;
  final _avatarChanges = StreamController<void>.broadcast();
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
  Stream<Account?> get changes {
    final sdk = auth;
    if (sdk == null) return Stream.value(null);
    return Stream.multi((controller) {
      var version = 0;
      var active = true;
      Future<void> emit(User? user) async {
        final currentVersion = ++version;
        String? localPhoto;
        if (user != null) {
          try {
            localPhoto = await avatars?.readPath(user.uid);
          } catch (_) {
            // An unavailable local file must not prevent session restoration.
          }
        }
        if (!active || currentVersion != version) return;
        controller.add(
          user == null
              ? null
              : Account(
                  id: user.uid,
                  email: user.email ?? '',
                  name: user.displayName ?? '',
                  photoUrl: user.photoURL,
                  localPhotoPath: localPhoto,
                ),
        );
      }

      final session = sdk.userChanges().listen(
        emit,
        onError: controller.addError,
      );
      final photos = _avatarChanges.stream.listen((_) => emit(sdk.currentUser));
      controller.onCancel = () async {
        active = false;
        await session.cancel();
        await photos.cancel();
      };
    });
  }

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
    final local = avatars;
    if (user == null || local == null) {
      throw const AuthFailure('Войдите в аккаунт, чтобы сохранить фото.');
    }
    try {
      await local.save(user.uid, bytes);
    } catch (_) {
      throw const AuthFailure(
        'Не удалось сохранить фото. Проверьте свободное место и выберите изображение до 5 МБ.',
      );
    }
    _avatarChanges.add(null);
  });
  @override
  Future<void> logout() async {
    await _run(_auth.signOut);
    if (googleConfigured) {
      try {
        if (!_googleInitialized) {
          await GoogleSignIn.instance.initialize(
            serverClientId: googleClientId,
          );
          _googleInitialized = true;
        }
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase session has already ended. */
      }
    }
  }
}
