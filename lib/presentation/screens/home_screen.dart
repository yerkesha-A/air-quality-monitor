import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/usecases/air_advice.dart';
import '../bloc/air_bloc.dart';
import '../providers/settings_controller.dart';
import '../widgets/air_chart.dart';
import '../widgets/primitives.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AirBloc, AirState>(
    builder: (context, state) {
      final report = state.report;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Air Quality',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Местоположение',
              onPressed: state.busy
                  ? null
                  : () => context.read<AirBloc>().add(const LocateAir()),
              icon: const Icon(Icons.my_location_outlined),
            ),
            IconButton(
              tooltip: 'Предупреждения',
              onPressed: () => context.push('/alerts'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        body: PageBody(
          onRefresh: () async {
            final bloc = context.read<AirBloc>();
            if (bloc.state.place == null || bloc.state.busy) return;
            final done = bloc.stream.firstWhere((s) => !s.busy);
            bloc.add(const RefreshAir());
            await done;
          },
          children: [
            const Eyebrow('СЕГОДНЯ · US AQI'),
            const SizedBox(height: 14),
            Text(
              'Ваш воздух.\nВаш день.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.place_outlined, size: 18),
                label: Text(state.place?.name ?? 'Выбрать город'),
                onPressed: () => context.go('/cities'),
              ),
            ),
            const SizedBox(height: 20),
            if (state.busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (state.message != null)
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message!),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () =>
                              context.read<AirBloc>().add(const RefreshAir()),
                          child: const Text('Повторить'),
                        ),
                        TextButton(
                          onPressed: () => context.go('/cities'),
                          child: const Text('Выбрать город'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (report == null && !state.busy && state.message == null)
              EmptyMessage(
                title: 'Начнём с вашего города',
                message: 'Найдите город или используйте местоположение. Здесь появится актуальная оценка качества воздуха.',
                action: FilledButton.icon(
                  onPressed: () => context.go('/cities'),
                  icon: const Icon(Icons.search),
                  label: const Text('Найти город'),
                ),
              ),
            if (report != null) ...[
              _AqiCard(report: report),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${report.offline ? 'Офлайн · ' : ''}${report.isStale(DateTime.now().toUtc()) ? 'Сохранённые данные · ' : ''}Получено ${dateLabel(report.fetchedAt.toLocal())} в ${clockLabel(report.fetchedAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Обновить',
                    onPressed: state.busy
                        ? null
                        : () => context.read<AirBloc>().add(const RefreshAir()),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AirAdvice.summary(report.current.aqi),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SectionTitle(
                'Ближайшие 24 часа',
                action: const Icon(Icons.schedule_outlined, size: 20),
              ),
              Surface(
                child: AirChart(
                  points: report.upcoming(DateTime.now().toUtc()),
                  offsetSeconds: report.utcOffsetSeconds,
                ),
              ),
              const SizedBox(height: 12),
              _ForecastHours(report: report),
              _BestHour(report: report),
              SectionTitle(
                'Состав воздуха',
                action: IconButton(
                  tooltip: 'О загрязнителях',
                  onPressed: () => context.push('/insights'),
                  icon: const Icon(Icons.info_outline),
                ),
              ),
              _Pollutants(report: report),
              const SectionTitle('Планы на сегодня'),
              Surface(
                child: Column(
                  children: [
                    _ActivityRow(
                      icon: Icons.directions_walk_outlined,
                      title: 'Прогулка',
                      subtitle: AirAdvice.activity(report.current.aqi),
                    ),
                    const Divider(height: 24),
                    _ActivityRow(
                      icon: Icons.directions_run_outlined,
                      title: 'Пробежка',
                      subtitle: AirAdvice.activity(
                        report.current.aqi,
                        intense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push('/health'),
                        child: const Text('Все рекомендации →'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/notes'),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Заметка о месте'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${report.place.name}: ${report.current.aqi?.round()} US AQI, ${report.current.band?.label}.\nОценка атмосферной модели на ${dateLabel(report.cityTime(report.current.time))} ${clockLabel(report.cityTime(report.current.time))}.\n${AirAdvice.summary(report.current.aqi)}\nИсточник: Open-Meteo / CAMS. ${report.offline ? 'Сохранённые офлайн-данные.' : ''}',
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Поделиться'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Источник: Open-Meteo / Copernicus CAMS. Оценка атмосферной модели, не измерение ближайшей станции. Прогноз может отличаться от условий у конкретной дороги.',
                style: TextStyle(fontSize: 11, height: 1.5),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _AqiCard extends StatelessWidget {
  const _AqiCard({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) => Surface(
    color: AppTheme.forest,
    padding: const EdgeInsets.all(26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Eyebrow('КАЧЕСТВО ВОЗДУХА', color: Color(0xffd5dfc9)),
            ),
            Icon(
              Icons.air_rounded,
              color: Color(report.current.band?.color ?? 0xffa8bc87),
              size: 26,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  report.current.aqi?.round().toString() ?? '—',
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 86,
                    height: 1.1,
                    color: AppTheme.cream,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 14, bottom: 12),
              child: Text(
                'US AQI',
                style: TextStyle(color: Color(0xffb7c9b0), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color(report.current.band?.color ?? 0xffa8bc87),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              report.current.band?.label ?? 'Нет данных',
              style: const TextStyle(
                color: AppTheme.cream,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: AirBand.values.map((b) => Color(b.color)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '0 · Хороший',
                style: TextStyle(color: Color(0xffb7c9b0), fontSize: 10),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '500 · Опасный',
                textAlign: TextAlign.right,
                style: TextStyle(color: Color(0xffb7c9b0), fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'На ${clockLabel(report.cityTime(report.current.time))} · оценка модели',
          style: const TextStyle(color: Color(0xffb7c9b0), fontSize: 11),
        ),
      ],
    ),
  );
}

class _Pollutants extends StatelessWidget {
  const _Pollutants({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) {
    final mg = context.watch<SettingsController>().milligrams;
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: pollutantLabels.entries.map((e) {
          final value = report.current.values[e.key];
          return SizedBox(
            width: (constraints.maxWidth - 12) / 2,
            child: Surface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(e.value),
                  const SizedBox(height: 12),
                  Text(
                    value == null
                        ? '—'
                        : (value / (mg ? 1000 : 1)).toStringAsFixed(mg ? 3 : 1),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    value == null
                        ? 'Нет данных'
                        : mg
                        ? 'мг/м³'
                        : 'мкг/м³',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ForecastHours extends StatelessWidget {
  const _ForecastHours({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) {
    final points = report.upcoming(DateTime.now().toUtc());
    final extraScale = (MediaQuery.textScalerOf(context).scale(13) / 13 - 1)
        .clamp(0.0, 3.0);
    return SizedBox(
      height: 96 + extraScale * 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: points.length,
        itemBuilder: (context, index) {
          final point = points[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 64 + extraScale * 32,
              child: Surface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      clockLabel(report.cityTime(point.time)),
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color: Color(point.band?.color ?? 0xffaaaaaa),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      point.aqi?.round().toString() ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BestHour extends StatelessWidget {
  const _BestHour({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) {
    final best = AirAdvice.bestHour(report.upcoming(DateTime.now().toUtc()));
    if (best == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Surface(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .6),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Лучший час: ${clockLabel(report.cityTime(best.time))}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${best.aqi!.round()} US AQI · минимум в прогнозе на 24 часа',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 26),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle),
          ],
        ),
      ),
    ],
  );
}
