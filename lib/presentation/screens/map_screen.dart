import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/services/device_service.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../bloc/air_bloc.dart';
import '../providers/places_controller.dart';
import '../widgets/primitives.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final Future<Map<String, dynamic>> _device = DeviceService().info();
  GoogleMapController? _map;
  LatLng? _center;
  AirReport? _preview;
  String? _error;
  bool _loading = false;
  int _revision = 0;
  final Map<String, AirReport> _reports = {};
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final repository = context.read<AirRepository>();
    final favorites = context
        .read<PlacesController>()
        .favorites
        .take(8)
        .toList();
    for (final place in favorites) {
      final report = await repository.cached(place);
      if (report != null && mounted) {
        setState(() => _reports[place.id] = report);
      }
    }
  }

  Future<void> _select(LatLng point) async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    final place = Place(
      id: 'map:${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}',
      name: 'Точка на карте',
      latitude: point.latitude,
      longitude: point.longitude,
      region:
          '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}',
    );
    try {
      final report = await context.read<AirRepository>().fetch(place);
      if (mounted && revision == _revision) {
        setState(() {
          _preview = report;
          _reports[place.id] = report;
        });
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() => _error = 'Нет данных для выбранной области.');
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Карта воздуха'),
      actions: [
        IconButton(
          tooltip: 'Моё местоположение',
          onPressed: () async {
            try {
              final place = await context.read<AirRepository>().locate();
              if (!context.mounted) return;
              _map?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(place.latitude, place.longitude),
                  10,
                ),
              );
              context.read<AirBloc>().add(LoadAir(place));
            } catch (e) {
              if (context.mounted) showMessage(context, e.toString());
            }
          },
          icon: const Icon(Icons.my_location_outlined),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _device,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data?['mapsConfigured'] != true) {
          return const PageBody(
            children: [
              EmptyMessage(
                title: 'Карта ещё не подключена',
                message: 'Для карты требуется подключение сервиса Google Maps. Поиск городов, GPS и показатели воздуха доступны на соседних экранах.',
                icon: Icons.map_outlined,
              ),
            ],
          );
        }
        final current = context.watch<AirBloc>().state.report;
        final target = current == null
            ? const LatLng(43.25249, 76.9115)
            : LatLng(current.place.latitude, current.place.longitude);
        final reports = <String, AirReport>{..._reports};
        if (current != null) {
          reports[current.place.id] = current;
        }
        return SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: target,
                    zoom: 9,
                  ),
                  onMapCreated: (controller) {
                    _map = controller;
                    _center = target;
                  },
                  onTap: _select,
                  onCameraMove: (position) => _center = position.target,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: reports.values
                      .map(
                        (r) => Marker(
                          markerId: MarkerId(r.place.id),
                          position: LatLng(r.place.latitude, r.place.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            r.current.aqi! <= 50
                                ? BitmapDescriptor.hueGreen
                                : r.current.aqi! <= 100
                                ? BitmapDescriptor.hueYellow
                                : r.current.aqi! <= 150
                                ? BitmapDescriptor.hueOrange
                                : BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(
                            title: r.place.name,
                            snippet:
                                '${r.current.aqi!.round()} US AQI${r.offline || r.isStale(DateTime.now()) ? ' · кеш' : ''}',
                          ),
                          onTap: () => setState(() => _preview = r),
                        ),
                      )
                      .toSet(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) Text(_error!),
                    if (_preview != null) ...[
                      Text(
                        '${_preview!.current.aqi!.round()} US AQI · ${_preview!.current.band!.label}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('${_preview!.place.subtitle} · оценка модели'),
                      Text(
                        '${_preview!.offline ? 'Офлайн · ' : ''}${dateLabel(_preview!.fetchedAt.toLocal())} ${clockLabel(_preview!.fetchedAt.toLocal())}',
                      ),
                      TextButton(
                        onPressed: () => context.read<AirBloc>().add(
                          LoadAir(_preview!.place),
                        ),
                        child: const Text('Выбрать это место'),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () => _select(_center ?? target),
                        child: const Text('Проверить воздух в центре карты'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Нажмите на карту для выбора места. Данные: Open-Meteo / CAMS.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
