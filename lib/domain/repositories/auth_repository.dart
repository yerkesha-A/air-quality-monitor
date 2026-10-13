import 'dart:typed_data';

class Account {
  const Account({
    required this.id,
    required this.email,
    this.name = '',
    this.photoUrl,
  });
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
}

abstract interface class AuthRepository {
  bool get configured;
  bool get googleConfigured;
  Stream<Account?> get changes;
  Future<void> login(String email, String password);
  Future<void> register(String email, String password, String name);
  Future<void> google();
  Future<void> reset(String email);
  Future<void> updateName(String name);
  Future<void> updateAvatar(Uint8List bytes);
  Future<void> logout();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
