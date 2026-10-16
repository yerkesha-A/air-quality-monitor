// Explicit internal target, never imported by the normal application entrypoint.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart' as product;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final app = await Firebase.initializeApp(
    name: 'password-reset-test',
    options: Firebase.app().options,
  );
  runApp(
    MaterialApp(
      home: _Verification(auth: FirebaseAuth.instanceFor(app: app)),
    ),
  );
}

class _Verification extends StatefulWidget {
  const _Verification({required this.auth});
  final FirebaseAuth auth;
  @override
  State<_Verification> createState() => _VerificationState();
}

class _VerificationState extends State<_Verification> {
  final password = TextEditingController();
  bool busy = false;
  bool verified = false;
  String? message;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> check() async {
    if (busy || password.text.isEmpty) return;
    setState(() {
      busy = true;
      message = null;
    });
    final owner = FirebaseAuth.instance.currentUser?.uid;
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: const String.fromEnvironment('RESET_TEST_EMAIL'),
        password: password.text,
      );
      password.clear();
      await widget.auth.signOut();
      if (FirebaseAuth.instance.currentUser?.uid != owner) {
        throw StateError('Owner session changed');
      }
      await File(
        '${(await getApplicationDocumentsDirectory()).path}/secondary-reset-complete.json',
      ).writeAsString(
        jsonEncode({
          'passwordLoginVerified': true,
          'ownerSessionPreserved': true,
          'verifiedAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      if (mounted) {
        setState(() {
          verified = true;
          message = 'Вход с новым паролем и выход проверены. Google-сессия сохранена.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          message =
              'Не удалось войти (${error.code}). Проверьте новый пароль тестового аккаунта.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          message = 'Не удалось завершить проверку. Повторите позже.';
        });
      }
    } finally {
      password.clear();
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Проверка тестового аккаунта')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Введите новый пароль отдельного тестового аккаунта прямо здесь. Не отправляйте пароль в чат. Google-аккаунт не меняется.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Новый тестовый пароль',
                ),
                onSubmitted: (_) => check(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy || verified ? null : check,
                child: const Text('Проверить вход и выход'),
              ),
              if (busy) const LinearProgressIndicator(),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(message!),
                ),
              if (verified)
                TextButton(
                  onPressed: product.main,
                  child: const Text('Вернуться в приложение'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
