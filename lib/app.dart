import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/air_repository.dart';
import 'presentation/bloc/air_bloc.dart';
import 'presentation/bloc/city_search_bloc.dart';
import 'presentation/bloc/history_bloc.dart';
import 'presentation/providers/auth_controller.dart';
import 'presentation/providers/places_controller.dart';
import 'presentation/providers/settings_controller.dart';

class AirQualityApp extends StatefulWidget {
  const AirQualityApp({
    super.key,
    required this.settings,
    required this.dependencies,
  });
  final SettingsController settings;
  final AppDependencies dependencies;
  @override
  State<AirQualityApp> createState() => _AirQualityAppState();
}

class _AirQualityAppState extends State<AirQualityApp> {
  late final _auth = AuthController(widget.dependencies.auth);
  late final _places = PlacesController(widget.dependencies.places);
  late final _air = AirBloc(
    widget.dependencies.air,
    widget.dependencies.places,
  );
  late final GoRouter _router = createRouter(widget.settings, _auth);
  Timer? _syncTimer;
  @override
  void initState() {
    super.initState();
    _auth.beforeLogout = widget.dependencies.firebase.unregisterDevice;
    _auth.addListener(_scheduleSync);
    _places.addListener(_scheduleSync);
    widget.settings.addListener(_scheduleSync);
    widget.dependencies.notifications.onOpen = _openNotification;
    widget.dependencies.firebase.onOpen = _openNotification;
    _restore();
  }

  Future<void> _restore() async {
    final place = await widget.dependencies.places.selected();
    await _places.reload();
    if (!mounted) return;
    if (place != null) _air.add(LoadAir(place));
    final initial =
        widget.dependencies.notifications.initialRoute ??
        widget.dependencies.firebase.initialRoute;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNotification(initial);
      });
    }
  }

  void _openNotification(String route) {
    if (_router.routeInformationProvider.value.uri.path != route) {
      _router.push(route);
    }
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    final account = _auth.account;
    if (account == null || _auth.busy) return;
    _syncTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await widget.dependencies.firebase.sync(
          account: account,
          place: _air.state.place,
          favorites: _places.favorites,
          threshold: widget.settings.threshold,
          backgroundAlerts: widget.settings.backgroundAlerts,
          theme: widget.settings.themeMode.index,
          milligrams: widget.settings.milligrams,
        );
      } catch (_) {
        /* Cloud configuration/connectivity is shown separately; local data stays usable. */
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _auth.removeListener(_scheduleSync);
    _places.removeListener(_scheduleSync);
    widget.settings.removeListener(_scheduleSync);
    _router.dispose();
    _auth.dispose();
    _places.dispose();
    _air.close();
    widget.dependencies.firebase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.settings),
      ChangeNotifierProvider.value(value: _auth),
      ChangeNotifierProvider.value(value: _places),
      Provider.value(value: widget.dependencies.store),
      Provider.value(value: widget.dependencies.notifications),
      Provider.value(value: widget.dependencies.firebase),
      Provider<AirRepository>.value(value: widget.dependencies.air),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _air),
        BlocProvider(create: (_) => CitySearchBloc(widget.dependencies.air)),
        BlocProvider(create: (_) => HistoryBloc(widget.dependencies.air)),
      ],
      child: BlocListener<AirBloc, AirState>(
        listener: (context, state) async {
          if (!state.busy) {
            await _places.reload();
            _scheduleSync();
          }
          if (state.status == LoadStatus.success && state.report != null) {
            try {
              await widget.dependencies.notifications.check(
                state.report!,
                enabled: widget.settings.alertsEnabled,
                threshold: widget.settings.threshold,
              );
            } catch (_) {
              /* The dashboard remains available if system notifications are disabled. */
            }
          }
        },
        child: Consumer<SettingsController>(
          builder: (context, settings, _) => MaterialApp.router(
            title: 'Air Quality Monitor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(Brightness.light),
            darkTheme: AppTheme.create(Brightness.dark),
            themeMode: settings.themeMode,
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          ),
        ),
      ),
    ),
  );
}
