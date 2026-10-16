import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import 'package:provider/provider.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../providers/places_controller.dart';
import '../widgets/primitives.dart';
import 'city_picker_sheet.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _first = suggestedPlaces[0].id;
  String _second = suggestedPlaces[1].id;
  bool _loading = false;
  List<(Place, AirReport?, String?)> _results = [];
  Future<void> _compare(List<Place> places) async {
    setState(() {
      _loading = true;
      _results = [];
    });
    final repository = context.read<AirRepository>();
    final selected = [
      _first,
      _second,
    ].map((id) => places.firstWhere((p) => p.id == id));
    final results = await Future.wait(
      selected.map((place) async {
        try {
          return (place, await repository.fetch(place), null);
        } catch (_) {
          return (place, null, 'Нет доступных данных');
        }
      }),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _results = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<PlacesController>();
    final cities = <String, Place>{
      for (final p in [...suggestedPlaces, ...saved.recent, ...saved.favorites])
        p.id: p,
    }.values.toList();
    return AirScaffold(
      appBar: AppBar(title: const Text('Сравнение')),
      body: PageBody(
        children: [
          const Eyebrow('ДВА ГОРОДА · ОДНА ШКАЛА'),
          const SizedBox(height: 16),
          Text(
            'Где дышится легче?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _first,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Первый город'),
            items: cities
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (id) => setState(() {
                    _first = id!;
                    _results = [];
                  }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _second,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Второй город'),
            items: cities
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (id) => setState(() {
                    _second = id!;
                    _results = [];
                  }),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading || _first == _second
                ? null
                : () => _compare(cities),
            child: Text(_loading ? 'Загружаем…' : 'Сравнить воздух'),
          ),
          if (_first == _second)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Выберите два разных города.'),
            ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          ..._results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LandscapeAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result.$1.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (result.$2 == null)
                      Text(result.$3!)
                    else ...[
                      Text(
                        '${result.$2!.current.aqi!.round()} US AQI',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(result.$2!.current.band!.label),
                      const SizedBox(height: 12),
                      Text(
                        'PM₂.₅: ${result.$2!.current.values['pm2_5']?.toStringAsFixed(1) ?? '—'} мкг/м³',
                      ),
                      Text(
                        'PM₁₀: ${result.$2!.current.values['pm10']?.toStringAsFixed(1) ?? '—'} мкг/м³',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${result.$2!.offline ? '${result.$2!.cacheLabel} · ' : ''}${dateLabel(result.$2!.fetchedAt.toLocal())} ${clockLabel(result.$2!.fetchedAt.toLocal())}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Источник: Open-Meteo / CAMS. Сравниваются текущие оценки модели по US AQI. Время получения каждого набора указано отдельно.',
          ),
        ],
      ),
    );
  }
}
