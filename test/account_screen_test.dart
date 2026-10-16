import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:air_quality_monitor/core/theme/app_theme.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:air_quality_monitor/presentation/providers/auth_controller.dart';
import 'package:air_quality_monitor/presentation/screens/account_screen.dart';
import 'package:air_quality_monitor/presentation/widgets/account_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _Repository extends Mock implements AuthRepository {}

class _Picker extends Mock implements ImagePicker {}

void main() {
  const account = Account(
    id: 'a',
    email: 'long.email.for.adaptive.profile@example.com',
    name: 'Алия Абдраим очень длинное имя профиля',
  );
  late _Repository repo;
  late AuthController auth;
  setUp(() {
    repo = _Repository();
    when(() => repo.changes).thenAnswer((_) => Stream.value(account));
    auth = AuthController(repo);
  });
  tearDown(() => auth.dispose());

  Future<void> show(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
    ImagePicker? picker,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.create(Brightness.light),
          darkTheme: AppTheme.create(Brightness.dark),
          themeMode: mode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: AccountScreen(imagePicker: picker),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Account avatar stays 88px circular and profile scrolls at all supported sizes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(320, 568),
        const Size(740, 360),
        const Size(800, 1280),
        const Size(1280, 800),
      ]) {
        tester.view.physicalSize = size;
        for (final theme in [ThemeMode.light, ThemeMode.dark]) {
          await show(tester, mode: theme);
          expect(
            tester.getSize(find.byKey(const ValueKey('account-avatar'))),
            const Size(88, 88),
          );
          expect(
            find.descendant(
              of: find.byType(AccountAvatar),
              matching: find.byType(ClipOval),
            ),
            findsOneWidget,
          );
          expect(find.text('АП'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Выйти из аккаунта'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('Выйти из аккаунта').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  for (final source in [ImageSource.gallery, ImageSource.camera]) {
    testWidgets(
      'Photo source $source forwards selected photo bytes to local avatar action',
      (tester) async {
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
        );
        final picker = _Picker();
        when(
          () => picker.pickImage(
            source: source,
            maxWidth: 640,
            maxHeight: 640,
            imageQuality: 80,
          ),
        ).thenAnswer(
          (_) async =>
              XFile.fromData(bytes, mimeType: 'image/png', name: 'photo.png'),
        );
        registerFallbackValue(Uint8List(0));
        when(() => repo.updateAvatar(any())).thenAnswer((_) async {});
        await show(tester, picker: picker);
        await tester.tap(find.text('Изменить фото'));
        await tester.pumpAndSettle();
        expect(find.text('Выбрать из галереи'), findsOneWidget);
        expect(find.text('Сделать снимок'), findsOneWidget);
        await tester.tap(
          find.text(
            source == ImageSource.gallery
                ? 'Выбрать из галереи'
                : 'Сделать снимок',
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(
          verify(() => repo.updateAvatar(captureAny())).captured.single,
          bytes,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Explicit Back works for a directly opened account route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Profile destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Назад'));
    await tester.pumpAndSettle();
    expect(find.text('Profile destination'), findsOneWidget);
  });
}
