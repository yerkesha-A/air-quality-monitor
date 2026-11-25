import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/location_service.dart';
import '../../data/services/map_tiles.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../bloc/air_bloc.dart';
import '../controllers/map_air_controller.dart';
import '../providers/places_controller.dart';
import '../widgets/map_marker_layout.dart';
import '../widgets/primitives.dart';
import '../widgets/nature_components.dart';
import 'city_picker_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.tileProvider, this.location});
  final TileProvider? tileProvider;
  final LocationService? location;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final _map = MapController();
  final _mapViewKey = GlobalKey(debugLabel: 'air-map-viewport');
  final _tileReset = StreamController<void>.broadcast();
  late final _location = widget.location ?? LocationService();
  late final _tiles =
      widget.tileProvider ??
      (context.read<MapTilesFactory?>() ?? createMapTiles)();
  late final MapAirController _samples;
  late LatLng _center;
  final _cities = <String, AirReport>{};
  AirReport? _preview;
  LatLng? _userPosition;
  LocationFailure? _locationFailure;
  String? _error;
  String _variable = 'us_aqi';
  bool _mapReady = false;
  bool _loading = false;
  bool _locating = false;
  bool _permission = false;
  bool _pointSelected = false;
  bool _useMain = true;
  bool _tileError = false;
  bool _showRegional = true;
  bool _detailsExpanded = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    final place = context.read<AirBloc>().state.place ?? suggestedPlaces.first;
    _center = LatLng(place.latitude, place.longitude);
    _samples = MapAirController(context.read<AirRepository>())
      ..addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCities() async {
    final favorites = context.read<PlacesController>().favorites;
    final places = {
      for (final p in [...favorites, ...suggestedPlaces]) p.id: p,
    }.values;
    final reports = await _samples.loadPlaces(places);
    if (mounted) {
      setState(() => _cities.addAll({for (final r in reports) r.place.id: r}));
    }
  }

  Future<void> _select(LatLng point, {bool force = false}) async {
    final revision = ++_revision;
    setState(() {
      _useMain = false;
      _pointSelected = true;
      _preview = null;
      _loading = true;
      _error = null;
    });
    AirReport? report;
    try {
      report = await _samples.select(
        point.latitude,
        point.longitude,
        force: force,
      );
    } catch (_) {
      report = null;
    }
    if (!mounted || revision != _revision) return;
    setState(() {
      _preview = report;
      _loading = false;
      _error = report == null
          ? 'Для выбранной точки нет данных. Попробуйте другую точку.'
          : null;
    });
  }

  void _chooseReport(AirReport report) => setState(() {
    _revision++;
    _useMain = false;
    _pointSelected = true;
    _preview = report;
    _error = null;
    _loading = false;
  });

  Future<void> _openCity(Place place) async {
    final revision = ++_revision;
    setState(() {
      _useMain = false;
      _pointSelected = true;
      _preview = _cities[place.id];
      _loading = _preview == null;
      _error = null;
      _center = LatLng(place.latitude, place.longitude);
    });
    if (_mapReady) _map.move(_center, 10);
    if (_preview != null) return;
    final reports = await _samples.loadPlaces([place]);
    if (!mounted || revision != _revision) return;
    setState(() {
      _preview = reports.firstOrNull;
      if (_preview != null) _cities[place.id] = _preview!;
      _loading = false;
      if (_preview == null) _error = 'Данные для города временно недоступны.';
    });
  }

  void _cameraChanged(MapCamera camera, bool gesture) {
    _center = camera.center;
    final showRegional = camera.zoom >= 8;
    if (showRegional != _showRegional) {
      setState(() => _showRegional = showRegional);
    }
    if (!gesture) return;
    if (_pointSelected || _useMain || _loading) {
      setState(() {
        _revision++;
        _pointSelected = false;
        _useMain = false;
        _preview = null;
        _loading = false;
        _error = null;
      });
    }
    _samples.schedule(_center.latitude, _center.longitude);
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    try {
      final place = await _location.locate();
      if (!mounted) return;
      setState(() {
        _permission = true;
        _userPosition = LatLng(place.latitude, place.longitude);
        _center = _userPosition!;
      });
      if (_mapReady) _map.move(_center, 11);
      await _select(_center);
    } on LocationFailure catch (failure) {
      if (mounted) {
        setState(() {
          _permission = false;
          _locationFailure = failure;
        });
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _checkPermission() async {
    final allowed = await _location.hasPermission();
    if (!mounted) return;
    final failure = _locationFailure;
    final permissionRecovered =
        allowed &&
        (failure?.issue == LocationIssue.denied ||
            failure?.issue == LocationIssue.permanentlyDenied);
    final serviceRecovered =
        failure?.issue == LocationIssue.disabled &&
        await _location.serviceEnabled();
    if (!mounted) return;
    if (allowed != _permission || permissionRecovered || serviceRecovered) {
      setState(() {
        _permission = allowed;
        if (identical(_locationFailure, failure) &&
            (permissionRecovered || serviceRecovered)) {
          _locationFailure = null;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  void _overview() {
    if (!_mapReady) return;
    setState(() {
      _revision++;
      _loading = false;
      _pointSelected = false;
      _useMain = true;
      _error = null;
    });
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          for (final p in suggestedPlaces) LatLng(p.latitude, p.longitude),
        ]),
        padding: const EdgeInsets.all(48),
      ),
    );
    _samples.schedule(
      _map.camera.center.latitude,
      _map.camera.center.longitude,
    );
  }

  void _tileFailed() {
    if (_tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileError) setState(() => _tileError = true);
    });
  }

  Widget _controls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: AirSurface(
              padding: EdgeInsets.zero,
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.search_rounded),
                title: const Text('Поиск города…'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showCityPicker(context),
              ),
            ),
          ),
          PopupMenuButton<Place>(
            tooltip: 'Быстрый выбор города',
            icon: Icon(
              Icons.location_city_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onSelected: _openCity,
            itemBuilder: (_) => [
              for (final city in suggestedPlaces)
                PopupMenuItem(value: city, child: Text(city.name)),
            ],
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final variable in ['us_aqi', 'pm2_5', 'pm10'])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    variable == 'us_aqi'
                        ? 'US AQI'
                        : pollutantLabels[variable]!,
                  ),
                  selected: _variable == variable,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _variable = variable),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  void _legend() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Легенда US AQI',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Цвет маркера всегда обозначает категорию US AQI, в том числе при просмотре PM₂.₅ и PM₁₀.',
            ),
            for (final (index, band) in AirBand.values.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(band.color),
                  radius: 10,
                ),
                title: Text(band.label),
                subtitle: Text(
                  [
                    '0–50',
                    '51–100',
                    '101–150',
                    '151–200',
                    '201–300',
                    '301+',
                  ][index],
                ),
              ),
            const Text(
              '«+N» — соседние точки. Нажмите группу, чтобы выбрать точку. Число на маркере относится к одной реальной точке, это не среднее значение группы.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Open-Meteo / CAMS: модельные оценки, не показания уличных датчиков.',
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _markerPressed(List<AirReport> reports) async {
    if (reports.length == 1) {
      _chooseReport(reports.single);
      return;
    }
    final report = await showModalBottomSheet<AirReport>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: Column(
            children: [
              Text(
                'Точки рядом: ${reports.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (_, index) {
                    final r = reports[index];
                    return ListTile(
                      title: Text(
                        '${r.place.name} · ${r.current.aqi?.round() ?? '—'} US AQI',
                      ),
                      subtitle: Text(
                        '${r.place.latitude.toStringAsFixed(3)}, ${r.place.longitude.toStringAsFixed(3)}',
                      ),
                      onTap: () => Navigator.pop(context, r),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (report == null || !mounted) return;
    _chooseReport(report);
    if (_mapReady) {
      _map.move(
        LatLng(report.place.latitude, report.place.longitude),
        (_map.camera.zoom + 1).clamp(3, 18),
      );
    }
  }

  Widget _locationNotice() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_locating) const LinearProgressIndicator(),
      if (_locationFailure != null) ...[
        Text(_locationFailure!.message),
        if (_locationFailure!.issue == LocationIssue.disabled ||
            _locationFailure!.issue == LocationIssue.permanentlyDenied)
          TextButton(
            onPressed: () async {
              final opened = await _location.openSettings(
                _locationFailure!.issue,
              );
              if (!opened && mounted) {
                showMessage(context, 'Откройте настройки устройства вручную.');
              }
            },
            child: const Text('Открыть настройки'),
          ),
      ],
    ],
  );

  Widget _details(AirReport? report) => AirSurface(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loading || _samples.loading) const LinearProgressIndicator(),
        if (_locating || _locationFailure != null) _locationNotice(),
        if (_error != null) Text(_error!),
        if (_samples.error != null && !_pointSelected) Text(_samples.error!),
        if (report == null && !_loading && !_samples.loading)
          const Text(
            'Нажмите маркер или точку на карте, чтобы узнать качество воздуха.',
          ),
        if (report != null) ...[
          InkWell(
            key: const ValueKey('map-details-toggle'),
            onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${report.current.aqi?.round() ?? '—'} US AQI',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_detailsExpanded)
                          Text(
                            'Обновлено ${clockLabel(report.fetchedAt.toLocal())}',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: _detailsExpanded
                        ? 'Свернуть сведения'
                        : 'Подробнее о воздухе',
                    child: Icon(
                      _detailsExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (report.offline || report.isStale(DateTime.now()))
            Text(report.cacheLabel, style: const TextStyle(fontSize: 11)),
          if (_detailsExpanded) ...[
            const Divider(),
            if (report.place.region.isNotEmpty) Text(report.place.region),
            Text(report.current.band?.label ?? 'Нет данных о категории'),
            Text(
              'PM₂.₅: ${report.current.values['pm2_5']?.toStringAsFixed(1) ?? '—'} · PM₁₀: ${report.current.values['pm10']?.toStringAsFixed(1) ?? '—'} мкг/м³',
            ),
            Text(
              'Данные модели: ${dateLabel(report.cityTime(report.current.time))} ${clockLabel(report.cityTime(report.current.time))}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              'Обновлено ${dateLabel(report.fetchedAt.toLocal())} ${clockLabel(report.fetchedAt.toLocal())}',
              style: const TextStyle(fontSize: 11),
            ),
            TextButton(
              onPressed: () =>
                  context.read<AirBloc>().add(LoadAir(report.place)),
              child: const Text('Выбрать это место'),
            ),
          ],
        ],
        if (_detailsExpanded || report == null)
          TextButton.icon(
            onPressed: _loading ? null : () => _select(_center, force: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Проверить центр карты'),
          ),
      ],
    ),
  );

  Widget _mapView(
    Map<String, AirReport> reports, {
    bool compactLegend = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final markerSize = airMapMarkerSize(MediaQuery.textScalerOf(context));
    final tiles = TileLayer(
      urlTemplate: osmTileUrl,
      tileProvider: _tiles,
      userAgentPackageName: 'com.example.air_quality_monitor',
      maxNativeZoom: 19,
      panBuffer: 0,
      keepBuffer: 1,
      reset: _tileReset.stream,
      errorTileCallback: (_, _, _) => _tileFailed(),
    );
    return Column(
      key: _mapViewKey,
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                key: const ValueKey('air-quality-map'),
                mapController: _map,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 10,
                  minZoom: 3,
                  maxZoom: 18,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainer,
                  onMapReady: () {
                    _mapReady = true;
                    _samples.schedule(_center.latitude, _center.longitude);
                    _loadCities();
                  },
                  onPositionChanged: _cameraChanged,
                  onTap: (_, point) => _select(point),
                ),
                children: [
                  ColorFiltered(
                    colorFilter: dark
                        ? const ColorFilter.matrix([
                            -.18,
                            -.61,
                            -.061,
                            0,
                            230,
                            -.18,
                            -.61,
                            -.061,
                            0,
                            235,
                            -.18,
                            -.61,
                            -.061,
                            0,
                            245,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: tiles,
                  ),
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      if (_permission && _userPosition != null)
                        Marker(
                          point: _userPosition!,
                          width: markerSize.width + 12,
                          height: markerSize.height + 12,
                          child: Semantics(
                            label: 'Моё местоположение',
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: const ValueKey('user-location-marker'),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xff2987bc),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AirMapMarkers(
                    reports: reports.values.take(14).toList(),
                    variable: _variable,
                    selectedId: _pointSelected
                        ? _preview?.place.id
                        : context.read<AirBloc>().state.report?.place.id,
                    onSelect: _markerPressed,
                  ),
                ],
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Column(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Приблизить карту',
                      onPressed: () {
                        if (_mapReady) {
                          _map.move(
                            _map.camera.center,
                            (_map.camera.zoom + 1).clamp(3, 18),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 4),
                    IconButton.filledTonal(
                      tooltip: 'Отдалить карту',
                      onPressed: () {
                        if (_mapReady) {
                          _map.move(
                            _map.camera.center,
                            (_map.camera.zoom - 1).clamp(3, 18),
                          );
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
              if (_tileError)
                Positioned(
                  left: 8,
                  right: 64,
                  top: 8,
                  child: AirSurface(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Часть карты недоступна. Проверьте подключение.',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _tileError = false);
                            _tileReset.add(null);
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (compactLegend)
                IconButton(
                  tooltip: 'Легенда US AQI',
                  onPressed: _legend,
                  icon: const Icon(Icons.palette_outlined),
                )
              else
                TextButton.icon(
                  onPressed: _legend,
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: const Text("Легенда US AQI"),
                ),
              InkWell(
                onTap: () async {
                  try {
                    final opened = await launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && mounted) {
                      showMessage(context, 'Не удалось открыть ссылку.');
                    }
                  } catch (_) {
                    if (mounted) {
                      showMessage(context, 'Не удалось открыть ссылку.');
                    }
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: Semantics(
                    link: true,
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final main = context.select<AirBloc, AirReport?>(
      (bloc) => bloc.state.report,
    );
    final reports = <String, AirReport>{..._cities};
    if (main != null) reports[main.place.id] = main;
    final cityCells = {
      for (final r in reports.values)
        MapAirController.point(r.place.latitude, r.place.longitude).id,
    };
    for (final report in _samples.reports) {
      if (!cityCells.contains(report.place.id) &&
          (_showRegional ||
              (_pointSelected && _preview?.place.id == report.place.id))) {
        reports[report.place.id] = report;
      }
    }
    final centerId = MapAirController.point(
      _center.latitude,
      _center.longitude,
    ).id;
    final region = _samples.reports
        .where((r) => r.place.id == centerId)
        .firstOrNull;
    final selected = _pointSelected
        ? _preview
        : (_useMain ? main ?? region : region);
    return BlocListener<AirBloc, AirState>(
      listenWhen: (before, after) => before.place?.id != after.place?.id,
      listener: (_, state) {
        final place = state.place;
        if (place == null) return;
        setState(() {
          _revision++;
          _useMain = true;
          _pointSelected = false;
          _loading = false;
          _error = null;
          _center = LatLng(place.latitude, place.longitude);
        });
        if (_mapReady) _map.move(_center, 10);
        _samples.schedule(_center.latitude, _center.longitude);
      },
      child: AirScaffold(
        appBar: AppBar(
          title: const Text('Карта воздуха'),
          actions: [
            IconButton(
              tooltip: 'Все города',
              onPressed: _overview,
              icon: const Icon(Icons.map_outlined),
            ),
            IconButton(
              tooltip: 'Моё местоположение',
              onPressed: _locating ? null : _locate,
              icon: const Icon(Icons.my_location_outlined),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, size) {
              final wide =
                  size.maxWidth >= 600 && size.maxWidth > size.maxHeight;
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: _mapView(reports, compactLegend: true)),
                    SizedBox(
                      width: size.maxWidth * .43,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _controls(),
                            const SizedBox(height: 8),
                            _details(selected),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                    child: _controls(),
                  ),
                  Expanded(child: _mapView(reports)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          size.maxHeight * (_detailsExpanded ? .48 : .28),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                      child: _details(selected),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _samples.removeListener(_changed);
    _samples.dispose();
    _tileReset.close();
    _map.dispose();
    // TileLayer owns and disposes its TileProvider/HTTP client.
    super.dispose();
  }
}
