import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository) {
    _subscription = repository.changes.listen((user) {
      account = user;
      _notify();
    });
  }
  final AuthRepository repository;
  late final StreamSubscription<Account?> _subscription;
  Account? account;
  Future<void> Function()? beforeLogout;
  bool busy = false;
  String? error;
  bool _disposed = false;
  bool get configured => repository.configured;
  bool get googleConfigured => repository.googleConfigured;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> _perform(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      return true;
    } catch (e) {
      error = e is AuthFailure ? e.message : 'Не удалось выполнить действие. Проверьте подключение и настройки сервиса.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> login(String email, String password) =>
      _perform(() => repository.login(email, password));
  Future<bool> register(String email, String password, String name) =>
      _perform(() => repository.register(email, password, name));
  Future<bool> google() => _perform(repository.google);
  Future<bool> reset(String email) => _perform(() => repository.reset(email));
  Future<bool> updateName(String name) =>
      _perform(() => repository.updateName(name));
  Future<bool> updateAvatar(Uint8List bytes) =>
      _perform(() => repository.updateAvatar(bytes));
  Future<bool> logout() => _perform(() async {
    try {
      await beforeLogout?.call().timeout(const Duration(seconds: 3));
    } catch (_) {
      /* Cloud cleanup must not prevent native sign-out. */
    }
    await repository.logout();
  });
  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
