import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../widgets/account_avatar.dart';
import '../widgets/nature_components.dart';
import '../widgets/primitives.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.imagePicker});
  final ImagePicker? imagePicker;

  Future<void> _photo(BuildContext context, AuthController auth) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.pop(sheet, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать снимок'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Text('Фото сохраняется только на этом устройстве.'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    try {
      final image = await (imagePicker ?? ImagePicker()).pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 80,
      );
      if (image == null || !context.mounted) return;
      final saved = await auth.updateAvatar(await image.readAsBytes());
      if (saved && context.mounted) {
        showMessage(context, 'Фото сохранено на устройстве.');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          source == ImageSource.camera
              ? 'Не удалось открыть камеру. Можно выбрать фото из галереи.'
              : 'Не удалось открыть фото. Попробуйте другое изображение.',
        );
      }
    }
  }

  Future<void> _name(BuildContext context, AuthController auth) async {
    final controller = TextEditingController(text: auth.account?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: const Text('Ваше имя'),
        content: TextField(
          controller: controller,
          maxLength: 80,
          stylusHandwritingEnabled: false,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Имя'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialog, controller.text.trim());
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    // Let the closing dialog finish using its text field before disposing it.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (name != null) await auth.updateName(name);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final account = auth.account;
    final theme = Theme.of(context);
    return AirScaffold(
      appBar: AppBar(
        leadingWidth: 108,
        leading: TextButton.icon(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: const Text('Назад'),
        ),
        title: const Text('Аккаунт'),
      ),
      body: account == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: PageBody(
                  children: [
                    AirSurface(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          AccountAvatar(account: account),
                          const SizedBox(height: 18),
                          Text(
                            account.name.isEmpty ? 'Ваш профиль' : account.name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            account.email,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: auth.busy
                                ? null
                                : () => _photo(context, auth),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Изменить фото'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AirSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Личные данные',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: auth.busy
                                ? null
                                : () => _name(context, auth),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Изменить имя'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Выбранное фото хранится на этом устройстве и не загружается в облако.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          auth.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    if (auth.busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: auth.busy ? null : auth.logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Выйти из аккаунта'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
