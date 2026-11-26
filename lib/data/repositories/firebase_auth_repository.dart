import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../local/local_avatar_store.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository
    implements AuthRepository, AccountDeletionSupport, AppleAuthSupport {
  FirebaseAuthRepository({
    this.auth,
    this.avatars,
    this.googleClientId = '',
    this.googleIosClientId = '',
    this.appleEnabled = false,
    this.eraseCloudAccount,
  });
  final FirebaseAuth? auth;
  final LocalAvatarStore? avatars;
  final _avatarChanges = StreamController<void>.broadcast();
  final String googleClientId;
  final String googleIosClientId;
  final bool appleEnabled;
  final Future<void> Function(String uid)? eraseCloudAccount;
  bool _googleInitialized = false;
  @override
  bool get configured => auth != null;
  @override
  bool get googleConfigured =>
      configured && (googleClientId.isNotEmpty || googleIosClientId.isNotEmpty);
  @override
  bool get appleConfigured => configured && appleEnabled;
  @override
  bool get deletionConfigured => configured && eraseCloudAccount != null;
  @override
  bool get deletionNeedsPassword {
    final providers =
        auth?.currentUser?.providerData.map((p) => p.providerId).toSet() ??
        <String>{};
    return providers.contains('password') && !providers.contains('apple.com');
  }

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
        'user-mismatch' => 'Выберите аккаунт, в который вошли в приложении.',
        'canceled' ||
        'web-context-cancelled' => 'Подтверждение входа отменено.',
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
  Future<void> apple() => _run(() async {
    if (!appleConfigured) {
      throw const AuthFailure(
        'Вход с Apple ещё не настроен для этого устройства.',
      );
    }
    await _auth.signInWithProvider(
      AppleAuthProvider()
        ..addScope('email')
        ..addScope('name'),
    );
  });

  Future<AuthCredential> _googleCredential() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: googleIosClientId.isEmpty ? null : googleIosClientId,
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
    return GoogleAuthProvider.credential(idToken: token);
  }

  @override
  Future<void> google() => _run(() async {
    if (!googleConfigured) {
      throw const AuthFailure(
        'Google Sign-In ещё не настроен для этого устройства.',
      );
    }
    await _auth.signInWithCredential(await _googleCredential());
  });

  @override
  Future<void> deleteAccount({String? password}) => _run(() async {
    final erase = eraseCloudAccount;
    final user = _auth.currentUser;
    if (user == null || erase == null) {
      throw const AuthFailure('Войдите в аккаунт, чтобы удалить его.');
    }
    final providers = user.providerData.map((p) => p.providerId).toSet();
    String? appleCode;
    // Reauthenticate BEFORE the first destructive step, never switch accounts.
    if (providers.contains('apple.com')) {
      if (!appleConfigured) {
        throw const AuthFailure(
          'Подтверждение Apple недоступно. Обратитесь в поддержку.',
        );
      }
      final result = await user.reauthenticateWithProvider(AppleAuthProvider());
      appleCode = result.additionalUserInfo?.authorizationCode;
      if (appleCode == null || appleCode.isEmpty) {
        throw const AuthFailure(
          'Apple не подтвердил отзыв доступа. Повторите вход.',
        );
      }
    } else if (providers.contains('password')) {
      if (password == null || password.isEmpty || user.email == null) {
        throw const AuthFailure('Введите текущий пароль для подтверждения.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } else if (providers.contains('google.com') && googleConfigured) {
      await user.reauthenticateWithCredential(await _googleCredential());
    } else {
      throw const AuthFailure(
        'Этот способ подтверждения недоступен. Обратитесь в поддержку.',
      );
    }
    if (_auth.currentUser?.uid != user.uid) {
      throw const AuthFailure('Аккаунт изменился. Повторите действие.');
    }
    await user.getIdToken(true);
    try {
      await erase(user.uid);
      if (appleCode != null) {
        await _auth.revokeTokenWithAuthorizationCode(appleCode);
      }
      await avatars?.removeAccount(user.uid);
      await user.delete();
    } catch (_) {
      throw const AuthFailure(
        'Удаление не завершено. Не выходите из аккаунта: проверьте интернет и повторите удаление. При повторной ошибке обратитесь в поддержку.',
      );
    }
    // SDK deletion ends the Firebase session; provider logout is best effort.
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Session ended. */
      }
    }
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
            clientId: googleIosClientId.isEmpty ? null : googleIosClientId,
            serverClientId: googleClientId.isEmpty ? null : googleClientId,
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
