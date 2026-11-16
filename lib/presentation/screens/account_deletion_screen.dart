import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) => AirScaffold(
    appBar: AppBar(title: const Text('Удаление аккаунта')),
    body: PageBody(
      children: [
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
            await Clipboard.setData(const ClipboardData(text: supportEmail));
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
          'Локальные фотографии, заметки и история на устройстве не удаляются удалённо. Сохраните нужные материалы перед удалением локальных данных через настройки Android.',
        ),
      ],
    ),
  );
}
