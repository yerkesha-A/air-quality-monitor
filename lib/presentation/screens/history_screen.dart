import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/usecases/air_advice.dart';
import '../bloc/air_bloc.dart';
import '../bloc/history_bloc.dart';
import '../widgets/air_chart.dart';
import '../widgets/primitives.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _days = 1;
  String _variable = 'us_aqi';
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final place = context.read<AirBloc>().state.place;
    if (place != null) {
      context.read<HistoryBloc>().add(LoadHistory(place, _days));
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AirBloc, AirState>(
    listener: (_, _) => _reload(),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            tooltip: 'Обновить историю',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          final values = state.points
              .map((p) => p.values[_variable])
              .whereType<double>()
              .toList();
          final average = AirAdvice.average(values);
          final maximum = values.isEmpty
              ? null
              : values.reduce((a, b) => a > b ? a : b);
          final offset =
              context.read<AirBloc>().state.report?.utcOffsetSeconds ?? 0;
          return PageBody(
            children: [
              const Eyebrow('СОХРАНЁННЫЕ ДАННЫЕ'),
              const SizedBox(height: 16),
              Text(
                'Как меняется воздух',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(state.place?.name ?? 'Сначала выберите город'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  for (final days in [1, 7, 30])
                    ChoiceChip(
                      label: Text(days == 1 ? '24 часа' : '$days дней'),
                      selected: _days == days,
                      onSelected: (_) {
                        setState(() => _days = days);
                        _reload();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final variable in ['us_aqi', 'pm2_5', 'pm10'])
                    ChoiceChip(
                      label: Text(
                        variable == 'us_aqi'
                            ? 'US AQI'
                            : pollutantLabels[variable]!,
                      ),
                      selected: _variable == variable,
                      onSelected: (_) => setState(() => _variable = variable),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (state.status == LoadStatus.loading)
                const LinearProgressIndicator(),
              if (state.status == LoadStatus.error)
                EmptyMessage(
                  title: 'История недоступна',
                  message: state.message!,
                ),
              if (state.points.isEmpty && state.status != LoadStatus.loading)
                const EmptyMessage(
                  title: 'История начинается здесь',
                  message: 'При обновлении сохраняется текущая оценка модели. Архив будет накапливаться со временем. Прогноз не выдаётся за прошедшие измерения.',
                ),
              if (state.points.isNotEmpty) ...[
                Surface(
                  child: AirChart(
                    points: state.points,
                    variable: _variable,
                    offsetSeconds: offset,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Statistic('Среднее', average)),
                    const SizedBox(width: 12),
                    Expanded(child: _Statistic('Максимум', maximum)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _variable == 'us_aqi'
                      ? 'Шкала US AQI'
                      : 'Концентрация в мкг/м³',
                ),
                const SectionTitle('Календарь воздуха'),
                _Calendar(points: state.points, offsetSeconds: offset),
                const SectionTitle('Записи'),
                ...state.points.reversed
                    .take(48)
                    .map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${dateLabel(p.time.add(Duration(seconds: offset)))} · ${clockLabel(p.time.add(Duration(seconds: offset)))}',
                        ),
                        trailing: Text(
                          p.values[_variable]?.toStringAsFixed(1) ?? '—',
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              const Text(
                'История содержит только сохранённые приложением текущие оценки Open-Meteo / CAMS. Это не непрерывный архив станционных измерений. Средние рассчитаны по доступным точкам, а не по полному периоду.',
                style: TextStyle(fontSize: 11, height: 1.5),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Statistic extends StatelessWidget {
  const _Statistic(this.label, this.value);
  final String label;
  final double? value;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(
          value?.toStringAsFixed(1) ?? '—',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    ),
  );
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.points, required this.offsetSeconds});
  final List<AirPoint> points;
  final int offsetSeconds;
  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<double>>{};
    for (final point in points) {
      if (point.aqi == null) continue;
      final key = dateLabel(point.time.add(Duration(seconds: offsetSeconds)));
      grouped.putIfAbsent(key, () => []).add(point.aqi!);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grouped.entries.map((entry) {
        final aqi = AirAdvice.average(entry.value)!;
        return Tooltip(
          message:
              '${entry.key}: ${aqi.round()} US AQI, ${entry.value.length} точек',
          child: Container(
            width: 76,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(AirBand.forAqi(aqi).color).withValues(alpha: .45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(entry.key.substring(0, 5)),
                Text(
                  '${aqi.round()}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
