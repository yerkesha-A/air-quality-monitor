import 'package:air_quality_monitor/core/theme/app_theme.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/providers/places_controller.dart';
import 'package:air_quality_monitor/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'support/test_dependencies.dart';

import 'package:air_quality_monitor/presentation/widgets/aqi_marker.dart';

class _Location extends Mock implements LocationService {}

class _Tiles extends TestMapTiles {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  late _Location location;
  setUp(() {
    location = _Location();
    when(() => location.hasPermission()).thenAnswer((_) async => false);
  });

  Future<(_Tiles, ValueNotifier<ThemeMode>)> show(WidgetTester tester) async {
    final deps = testDependencies(selected: true);
    final bloc = AirBloc(deps.air, deps.places)
      ..add(const LoadAir(fixturePlace));
    final tiles = _Tiles();
    final theme = ValueNotifier(ThemeMode.light);
    final screen = MapScreen(tileProvider: tiles, location: location);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AirRepository>.value(value: deps.air),
          ChangeNotifierProvider(create: (_) => PlacesController(deps.places)),
          BlocProvider.value(value: bloc),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: theme,
          builder: (_, mode, _) => MaterialApp(
            theme: AppTheme.create(Brightness.light),
            darkTheme: AppTheme.create(Brightness.dark),
            themeMode: mode,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await bloc.close();
      theme.dispose();
    });
    return (tiles, theme);
  }

  testWidgets(
    'Interactive map, visible attribution, real report marker/card and city controls',
    (tester) async {
      await show(tester);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.text('© OpenStreetMap contributors').hitTestable(),
        findsOneWidget,
      );
      final marker = find.byKey(const ValueKey('map-marker-1526384'));
      expect(marker, findsOneWidget);
      await tester.tap(marker);
      await tester.pumpAndSettle();
      if (find.text('Точки рядом: 2').evaluate().isNotEmpty ||
          find.textContaining('Точки рядом:').evaluate().isNotEmpty) {
        await tester.tap(find.text('Алматы · 42 US AQI'));
        await tester.pumpAndSettle();
      }
      expect(find.text('42 US AQI'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-details-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PM₂.₅: 8.5'), findsOneWidget);
      expect(find.textContaining('Обновлено'), findsOneWidget);
      await tester.tap(find.byTooltip('Быстрый выбор города'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Астана'));
      await tester.pumpAndSettle();
      expect(find.text('Астана'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact card expands without covering the map; legend explains all bands',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await show(tester);
      final collapsed = tester.getSize(find.byType(FlutterMap)).height;
      expect(collapsed, greaterThan(300));
      expect(find.textContaining('PM₂.₅: 8.5'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('map-details-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PM₂.₅: 8.5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-details-toggle')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(FlutterMap)).height, collapsed);
      await tester.tap(find.text('Легенда US AQI'));
      await tester.pumpAndSettle();
      expect(find.text('0–50'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('301+'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Опасный'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Rotating the map keeps labels upright, visible and separated', (
    tester,
  ) async {
    await show(tester);
    tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .rotate(35);
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(FlutterMap));
    final labels = find.byType(AqiMapBadge);
    expect(labels.evaluate(), isNotEmpty);
    final rects = [
      for (final element in labels.evaluate())
        tester.getRect(find.byWidget(element.widget)),
    ];
    for (var i = 0; i < rects.length; i++) {
      expect(viewport.contains(rects[i].topLeft), isTrue);
      expect(viewport.contains(rects[i].bottomRight), isTrue);
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Granted GPS remains visible without intercepting AQI labels', (
    tester,
  ) async {
    when(() => location.locate()).thenAnswer((_) async => fixturePlace);
    await show(tester);
    await tester.tap(find.byTooltip('Моё местоположение'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('user-location-marker')), findsOneWidget);
    expect(find.byType(AqiMapBadge), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final issue in [
    LocationIssue.permanentlyDenied,
    LocationIssue.disabled,
  ]) {
    testWidgets(
      'Returning from settings clears recovered $issue without auto-locating',
      (tester) async {
        final failure = LocationFailure(issue, 'Старое ограничение');
        when(() => location.locate()).thenThrow(failure);
        await show(tester);
        await tester.tap(find.byTooltip('Моё местоположение'));
        await tester.pumpAndSettle();
        expect(find.text(failure.message), findsOneWidget);
        when(() => location.hasPermission()).thenAnswer((_) async => true);
        when(() => location.serviceEnabled()).thenAnswer((_) async => true);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text(failure.message), findsNothing);
        verify(() => location.locate()).called(1);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final issue in [
    LocationIssue.denied,
    LocationIssue.permanentlyDenied,
    LocationIssue.disabled,
  ]) {
    testWidgets(
      'Location $issue never removes the map and manual pan remains usable',
      (tester) async {
        final failure = LocationFailure(
          issue,
          'Проверка отказа: ${issue.name}',
        );
        when(() => location.locate()).thenThrow(failure);
        await show(tester);
        await tester.tap(find.byTooltip('Моё местоположение'));
        await tester.pumpAndSettle();
        expect(find.text(failure.message), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        if (issue != LocationIssue.denied) {
          expect(find.text('Открыть настройки'), findsOneWidget);
        }
        await tester.drag(find.byType(FlutterMap), const Offset(-70, 10));
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();
        expect(
          find.text('© OpenStreetMap contributors').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Theme and orientation preserve the map, controller and tile client',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final (tiles, theme) = await show(tester);
      theme.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(tiles.disposed, isFalse);
      tester.view.physicalSize = const Size(740, 360);
      await tester.pumpAndSettle();
      expect(tiles.disposed, isFalse);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.text('© OpenStreetMap contributors').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Приблизить карту'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
