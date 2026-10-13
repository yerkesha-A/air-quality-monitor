import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'city_picker_sheet.dart';
import '../widgets/nature_components.dart';
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
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? NatureStyle.milk
            : Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? NatureStyle.milk
              : Theme.of(context).colorScheme.surface,
          title: const AirWordmark(),
          titleSpacing: 20,
          actions: [
            QuietIconButton(
              tooltip: 'Предупреждения',
              onPressed: () => context.push('/alerts'),
              icon: Icons.notifications_none_rounded,
            ),
            const SizedBox(width: 8),
            QuietIconButton(
              tooltip: 'Настройки',
              onPressed: () => context.go('/profile'),
              icon: Icons.tune_rounded,
            ),
            const SizedBox(width: 16),
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
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('home-city-picker'),
                      onPressed: () => showCityPicker(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.place_outlined, size: 18),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              state.place?.name ?? 'Выбрать город',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Местоположение',
                  onPressed: state.busy
                      ? null
                      : () => context.read<AirBloc>().add(const LocateAir()),
                  icon: const Icon(Icons.near_me_outlined, size: 21),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                          onPressed: () => showCityPicker(context),
                          child: const Text('Выбрать город'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (report == null && state.busy)
              const _NatureHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Узнаём, чем дышит ваш город',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Загружаем актуальную оценку качества воздуха.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            if (report == null && !state.busy && state.message == null)
              _NatureHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow(
                      'ВАШ ВОЗДУХ · ВАШ РИТМ',
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Начнём с вашего города',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Выберите место, чтобы узнать качество воздуха и спланировать день.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showCityPicker(context),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Найти город'),
                    ),
                  ],
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
              _QuickPollutants(report: report),
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

class _NatureHero extends StatelessWidget {
  const _NatureHero({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              NatureStyle.mistyHills,
              fit: BoxFit.cover,
              alignment: const Alignment(.15, -.4),
              cacheWidth: 1000,
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff122c22).withValues(alpha: .08),
                    const Color(0xff122c22).withValues(alpha: .35),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Text(
                    'Ближе к природе. Ближе к себе.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                    ),
                  ),
                ),
                const SizedBox(height: 105),
                GlassSurface(tint: const Color(0xff284f55), child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AqiCard extends StatelessWidget {
  const _AqiCard({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) => _NatureHero(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Eyebrow('ВОЗДУХ СЕЙЧАС', color: Color(0xffe4efe5)),
            ),
            Text(
              clockLabel(report.cityTime(report.current.time)),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.current.aqi?.round().toString() ?? '—',
                  style: const TextStyle(
                    fontSize: 88,
                    height: 1,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'US AQI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Color(report.current.band?.color ?? 0xffa8bc87),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.current.band?.label ?? 'Нет данных',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Качество воздуха',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AqiScale(aqi: report.current.aqi),
        const SizedBox(height: 18),
        Text(
          AirAdvice.summary(report.current.aqi),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class _AqiScale extends StatelessWidget {
  const _AqiScale({this.aqi});
  final double? aqi;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 13,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      for (var i = 0; i < AirBand.values.length; i++)
                        Expanded(
                          flex: const [1, 1, 1, 1, 2, 4][i],
                          child: ColoredBox(
                            color: Color(AirBand.values[i].color),
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (aqi != null)
                Positioned(
                  left:
                      (constraints.maxWidth - 10) *
                      (aqi! / 500).clamp(0.0, 1.0),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(AirBand.forAqi(aqi!).color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 3),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '0 · Хороший',
              style: TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '500 · Опасный',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ),
        ],
      ),
    ],
  );
}

class _QuickPollutants extends StatelessWidget {
  const _QuickPollutants({required this.report});
  final AirReport report;
  @override
  Widget build(BuildContext context) {
    final mg = context.watch<SettingsController>().milligrams;
    return Row(
      children: [
        for (final entry in const {'pm2_5': 'PM₂.₅', 'pm10': 'PM₁₀'}.entries)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.key == 'pm2_5' ? 10 : 0),
              child: Surface(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Icon(Icons.blur_on_rounded, size: 16),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      report.current.values[entry.key] == null
                          ? '—'
                          : (report.current.values[entry.key]! /
                                    (mg ? 1000 : 1))
                                .toStringAsFixed(mg ? 3 : 1),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.current.values[entry.key] == null
                          ? 'Нет данных'
                          : mg
                          ? 'мг/м³'
                          : 'мкг/м³',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
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
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
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
                    'Лучшее время для прогулки',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clockLabel(report.cityTime(best.time)),
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
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
