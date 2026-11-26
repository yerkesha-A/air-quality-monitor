import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';

import '../../core/support/contact.dart';
import '../widgets/nature_components.dart';
import '../widgets/primitives.dart';

class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key, this.launcher});
  final Future<bool> Function(Uri)? launcher;

  Future<void> _compose(BuildContext context) async {
    try {
      final uri = accountDeletionEmail();
      final opened =
          await (launcher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && context.mounted) {
        showMessage(
          context,
          'Почтовое приложение недоступно. Напишите на $supportEmail.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Напишите запрос на $supportEmail.');
      }
    }
  }

  Future<void> _delete(BuildContext context, AuthController auth) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) =>
          _DeletionConfirmation(needsPassword: auth.deletionNeedsPassword),
    );
    if (password == null || !context.mounted) return;
    final deleted = await auth.deleteAccount(password: password);
    if (context.mounted) {
      showMessage(
        context,
        deleted
            ? 'Аккаунт и облачные данные удалены. Локальная история и заметки сохранены.'
            : auth.error ?? 'Не удалось завершить удаление.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController?>();
    final available = auth?.deletionConfigured == true && auth?.account != null;
    return PopScope(
      canPop: auth?.busy != true,
      child: AirScaffold(
        appBar: AppBar(title: const Text('Удаление аккаунта')),
        body: PageBody(
          children: [
            if (available) ...[
              const AirSurface(
                child: Text(
                  'Удаление нельзя отменить.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Будут удалены учётная запись, облачный профиль, настройки, избранное, регистрации push, облачные уведомления и фото профиля на этом устройстве. Перед удалением потребуется снова подтвердить вход.',
              ),
              const SizedBox(height: 12),
              const Text(
                'История измерений, заметки с фотографиями, избранное и настройки на этом устройстве используются и без аккаунта: они сохранятся. Удалённые устройства не очищаются дистанционно.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Для защиты от старых сеансов сохраняется служебная запись без имени, email и профиля. Поддержка удаляет её после истечения сеансов, не ранее 2 часов.',
              ),
              const SizedBox(height: 16),
              if (auth!.busy) const LinearProgressIndicator(),
              FilledButton.icon(
                onPressed: auth.busy ? null : () => _delete(context, auth),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Удалить мой аккаунт'),
              ),
              const SizedBox(height: 24),
            ],
            const AirSurface(
              child: Text(
                'Можно запросить удаление аккаунта и связанных облачных данных.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'После подтверждения владения аккаунтом разработчик удалит учётную запись, облачный профиль, настройки, избранное и регистрации устройств. Выход из аккаунта сам по себе ничего не удаляет.',
            ),
            const SizedBox(height: 16),
            const Text(
              'В запросе укажите email аккаунта. Не отправляйте пароль или коды подтверждения.',
            ),
            const SizedBox(height: 12),
            const SelectableText(supportEmail),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _compose(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Составить запрос'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: supportEmail),
                );
                if (context.mounted) showMessage(context, 'Адрес скопирован.');
              },
              child: const Text('Скопировать email'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Кнопка открывает черновик письма, а не удаляет данные немедленно. Обработка запроса выполняется разработчиком после проверки.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Локальные фотографии, заметки и история на устройстве не удаляются удалённо. Сохраните нужные материалы перед удалением локальных данных через настройки устройства.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletionConfirmation extends StatefulWidget {
  const _DeletionConfirmation({required this.needsPassword});
  final bool needsPassword;
  @override
  State<_DeletionConfirmation> createState() => _DeletionConfirmationState();
}

class _DeletionConfirmationState extends State<_DeletionConfirmation> {
  final _password = TextEditingController();
  bool _confirmed = false;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Удалить аккаунт навсегда?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Облачные данные и фото профиля будут удалены. Локальные заметки и история останутся. Это действие нельзя отменить.',
          ),
          if (widget.needsPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Текущий пароль'),
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Подтвердите тот же Google или Apple аккаунт в следующем окне.',
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Понимаю, что удаление необратимо'),
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value == true),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed:
            _confirmed && (!widget.needsPassword || _password.text.isNotEmpty)
            ? () => Navigator.pop(context, _password.text)
            : null,
        child: const Text('Подтвердить удаление'),
      ),
    ],
  );
}
