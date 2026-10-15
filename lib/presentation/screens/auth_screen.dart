import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../widgets/primitives.dart';
import '../widgets/nature_components.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _visible = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _emailError(String? value) =>
      value == null ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? 'Введите корректный email'
      : null;
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final success = _register
        ? await auth.register(
            _email.text.trim(),
            _password.text,
            _name.text.trim(),
          )
        : await auth.login(_email.text.trim(), _password.text);
    if (success && mounted) context.go('/account');
  }

  Future<void> _reset() async {
    if (_emailError(_email.text) != null) {
      showMessage(context, 'Сначала введите email в поле выше.');
      return;
    }
    final auth = context.read<AuthController>();
    final success = await auth.reset(_email.text.trim());
    if (mounted) {
      showMessage(
        context,
        success
            ? 'Если аккаунт существует, письмо для восстановления отправлено.'
            : auth.error ?? 'Не удалось отправить письмо. Повторите попытку.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аккаунт'),
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: PageBody(
        children: [
          const Align(alignment: Alignment.centerLeft, child: AirWordmark()),
          const SizedBox(height: 28),
          AirSurface(
            accent: const Color(0xffc1ddeb),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('ВАШЕ ПРОСТРАНСТВО'),
                const SizedBox(height: 16),
                Text(
                  _register ? 'Начните с себя' : 'С возвращением',
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ваш аккаунт для Air Quality. Следите за воздухом в своём ритме — мониторинг доступен и без входа.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!auth.configured)
            const Surface(
              child: Text(
                'Сервис аккаунтов ещё не подключён. Вход и регистрация станут доступны после настройки Firebase.',
              ),
            ),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  if (_register) ...[
                    TextFormField(
                      stylusHandwritingEnabled: false,
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Введите имя'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    stylusHandwritingEnabled: false,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: _emailError,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    stylusHandwritingEnabled: false,
                    controller: _password,
                    obscureText: !_visible,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (auth.configured && !auth.busy) {
                        _submit();
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    autocorrect: false,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    validator: (value) =>
                        value == null || value.length < (_register ? 8 : 1)
                        ? (_register ? 'Минимум 8 символов' : 'Введите пароль')
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      suffixIcon: IconButton(
                        tooltip: _visible ? 'Скрыть пароль' : 'Показать пароль',
                        onPressed: () => setState(() => _visible = !_visible),
                        icon: Icon(
                          _visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (auth.busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          FilledButton(
            onPressed: auth.busy || !auth.configured ? null : _submit,
            child: Text(
              auth.busy
                  ? 'Подождите…'
                  : _register
                  ? 'Создать аккаунт'
                  : 'Войти',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: auth.busy || !auth.googleConfigured
                ? null
                : () async {
                    final success = await auth.google();
                    if (success && context.mounted) context.go('/account');
                  },
            child: const Text('Продолжить с Google'),
          ),
          if (auth.configured && !auth.googleConfigured)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Google Sign-In ещё не подключён.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          TextButton(
            onPressed: auth.busy || !auth.configured ? null : _reset,
            child: const Text('Забыли пароль?'),
          ),
          TextButton(
            onPressed: auth.busy
                ? null
                : () => setState(() => _register = !_register),
            child: Text(
              _register
                  ? 'Уже есть аккаунт? Войти'
                  : 'Нет аккаунта? Зарегистрироваться',
            ),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Продолжить без аккаунта'),
          ),
        ],
      ),
    );
  }
}
