import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/air_quality.dart';
import '../bloc/air_bloc.dart';
import '../bloc/city_search_bloc.dart';
import '../providers/places_controller.dart';
import '../widgets/primitives.dart';

const suggestedPlaces = [
  Place(
    id: '1526384',
    name: 'Алматы',
    latitude: 43.25249,
    longitude: 76.9115,
    country: 'Казахстан',
  ),
  Place(
    id: '1526273',
    name: 'Астана',
    latitude: 51.1801,
    longitude: 71.44598,
    country: 'Казахстан',
  ),
  Place(
    id: '1518980',
    name: 'Шымкент',
    latitude: 42.3,
    longitude: 69.6,
    country: 'Казахстан',
  ),
];

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});
  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    context.read<PlacesController>().reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlacesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Города'),
        actions: [
          IconButton(
            tooltip: 'Сравнить города',
            onPressed: () => context.push('/compare'),
            icon: const Icon(Icons.compare_arrows_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Найдите своё место'),
                  const SizedBox(height: 12),
                  Text(
                    'Воздух без границ',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => context.read<CitySearchBloc>().add(
                      SearchChanged(value),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Город, например Алматы',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: () {
                          _search.clear();
                          context.read<CitySearchBloc>().add(
                            const SearchChanged(''),
                          );
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      context.read<AirBloc>().add(const LocateAir());
                      context.go('/');
                    },
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Моё местоположение'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CitySearchBloc, CitySearchState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == LoadStatus.error ||
                      state.status == LoadStatus.empty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        EmptyMessage(
                          title: state.status == LoadStatus.error
                              ? 'Поиск недоступен'
                              : 'Город не найден',
                          message: state.message ?? 'Уточните написание. Можно искать на русском или латиницей.',
                          action: state.status == LoadStatus.error
                              ? FilledButton(
                                  onPressed: () => context
                                      .read<CitySearchBloc>()
                                      .add(SearchChanged(_search.text)),
                                  child: const Text('Повторить'),
                                )
                              : null,
                        ),
                      ],
                    );
                  }
                  if (state.status == LoadStatus.success) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: state.results.length,
                      itemBuilder: (context, index) =>
                          _tile(state.results[index], places),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (places.favorites.isNotEmpty) ...[
                        const SectionTitle('Избранные'),
                        ...places.favorites.map((p) => _tile(p, places)),
                      ],
                      if (places.recent.isNotEmpty) ...[
                        const SectionTitle('Недавно смотрели'),
                        ...places.recent.map((p) => _tile(p, places)),
                      ],
                      const SectionTitle('Начните с города'),
                      ...suggestedPlaces.map((p) => _tile(p, places)),
                      const SizedBox(height: 24),
                      const Text(
                        'Поиск: Open-Meteo / GeoNames',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Place place, PlacesController places) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    leading: const Icon(Icons.location_city_outlined),
    title: Text(place.name),
    subtitle: Text(place.subtitle),
    trailing: IconButton(
      tooltip: places.isFavorite(place)
          ? 'Убрать из избранного'
          : 'В избранное',
      icon: Icon(
        places.isFavorite(place)
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
      ),
      onPressed: () async {
        try {
          await places.toggle(place);
        } catch (_) {
          if (mounted) showMessage(context, 'Не удалось сохранить избранное.');
        }
      },
    ),
    onTap: () {
      FocusScope.of(context).unfocus();
      context.read<AirBloc>().add(LoadAir(place));
      context.go('/');
    },
  );
}
