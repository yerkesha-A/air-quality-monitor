import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../widgets/primitives.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final account = auth.account;
    if (account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль аккаунта')),
      body: PageBody(
        children: [
          const Eyebrow('ВАШ АККАУНТ'),
          const SizedBox(height: 24),
          if (account.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                account.photoUrl!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person_outline, size: 64),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            account.name.isEmpty ? 'Ваш профиль' : account.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(account.email),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(auth.error!),
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: auth.busy
                ? null
                : () async {
                    final controller = TextEditingController(
                      text: account.name,
                    );
                    final name = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ваше имя'),
                        content: TextField(
                          controller: controller,
                          maxLength: 80,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                Navigator.pop(context, controller.text.trim());
                              }
                            },
                            child: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    );
                    controller.dispose();
                    if (name != null) await auth.updateName(name);
                  },
            child: const Text('Изменить имя'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    try {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        maxWidth: 640,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        await auth.updateAvatar(await image.readAsBytes());
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showMessage(context, 'Камера недоступна.');
                      }
                    }
                  },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Сделать фото профиля'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: auth.busy ? null : auth.logout,
            child: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
