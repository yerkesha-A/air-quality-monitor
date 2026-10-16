import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.account, this.size = 88});
  final Account account;
  final double size;

  String get initials {
    final words = account.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return account.email.isEmpty
          ? '?'
          : account.email.characters.first.toUpperCase();
    }
    return [
      words.first,
      if (words.length > 1) words.last,
    ].map((word) => word.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * .32,
            fontWeight: FontWeight.w600,
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final local = account.localPhotoPath;
    Widget remote() => account.photoUrl?.startsWith('https://') == true
        ? Image.network(
            account.photoUrl!,
            fit: BoxFit.cover,
            cacheWidth: pixels,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          )
        : fallback;
    return Semantics(
      label: 'Фото профиля',
      image: true,
      child: SizedBox.square(
        key: const ValueKey('account-avatar'),
        dimension: size,
        child: ClipOval(
          child: local != null
              ? Image.file(
                  File(local),
                  fit: BoxFit.cover,
                  cacheWidth: pixels,
                  errorBuilder: (_, _, _) => remote(),
                )
              : remote(),
        ),
      ),
    );
  }
}
