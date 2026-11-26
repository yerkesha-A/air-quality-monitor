import 'dart:io';
import 'dart:ui' as ui;

import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/core/theme/app_theme.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:air_quality_monitor/presentation/widgets/notification_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

Map<String, Object?> record(int index, {String? body}) => Map.unmodifiable({
  'id': 'alert-$index',
  'title': index == 2
      ? 'Воздух в Петропавловске-Камчатском'
      : 'Воздух в Алматы',
  'body':
      body ??
      '${[42, 86, 125, 175, 250, 350][index % 6]} US AQI — выше вашего порога 25. Оценка модели.',
  'created': DateTime(2026, 11, 26, 20, 10).millisecondsSinceEpoch,
  'source': index.isEven ? 'local' : 'fcm',
});

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RECORD_ALERT_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('notification-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('docs/notification_history_20261126');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Notification history: $platform $brightness, narrow/large text/empty',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(393, 852);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          SharedPreferences.setMockInitialValues({'onboarded': true});
          final settings = SettingsController(
            await SharedPreferences.getInstance(),
          );
          await settings.setTheme(
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          );
          final dependencies = testDependencies(selected: true);
          var records = List.generate(6, record);
          when(() => dependencies.store.alertsPage(after: any(named: 'after')))
              .thenAnswer((_) async => records);
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('notification-preview'),
              child: AirQualityApp(
                settings: settings,
                dependencies: dependencies,
              ),
            ),
          );
          await tester.pumpAndSettle();
          GoRouter.of(tester.element(find.byType(HomeScreen))).go('/alerts');
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(
            tester.element(find.byType(NotificationHistoryHeading)),
          );
          await tester.pumpAndSettle();
          expect(find.text('История уведомлений'), findsOneWidget);
          expect(find.text('86 US AQI'), findsOneWidget);
          expect(find.text('Умеренный'), findsOneWidget);
          expect(
            find.text('25 US AQI'),
            findsNothing,
            reason: 'Personal threshold must not become measured AQI',
          );
          await preview(tester, '${platform.name}-${brightness.name}');

          for (final (width, scale) in [
            (320.0, 1.5),
            (393.0, 2.0),
            (820.0, 1.0),
          ]) {
            tester.view.physicalSize = Size(width, 852);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await tester.pumpAndSettle();
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
            for (var i = 0; i < records.length; i++) {
              await tester.scrollUntilVisible(
                find.text('${[42, 86, 125, 175, 250, 350][i]} US AQI'),
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '$platform $brightness, width $width, text $scale, band $i',
              );
            }
          }
          expect(find.text('Все записи загружены'), findsNothing);
          records = [];
          tester.view.physicalSize = const Size(393, 852);
          tester.platformDispatcher.textScaleFactorTestValue = 1;
          await tester.tap(find.byTooltip('Обновить историю'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(NotificationHistoryHeading));
          await tester.pumpAndSettle();
          expect(find.text('Пока нет уведомлений'), findsOneWidget);
          expect(find.byType(NotificationHistoryCard), findsNothing);
          expect(tester.takeException(), isNull);
          await preview(tester, '${platform.name}-${brightness.name}-empty');
          verifyNever(
            () => dependencies.store.recordAlert(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              source: any(named: 'source'),
            ),
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }

  testWidgets(
    'Legacy and arbitrary messages retain content without invented AQI',
    (tester) async {
      const message = 'Проверка сервера: порог 25 US AQI, измерения нет';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.light),
          home: Scaffold(
            body: NotificationHistoryCard(record: record(0, body: message)),
          ),
        ),
      );
      expect(find.text(message), findsOneWidget);
      expect(find.text('Хороший'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('26.11.2026'), findsOneWidget);
      expect(find.text('20:10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
