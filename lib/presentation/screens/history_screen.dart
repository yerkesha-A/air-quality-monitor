import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/local_store.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/usecases/air_advice.dart';
import '../bloc/air_bloc.dart';
import '../bloc/history_bloc.dart';
import '../widgets/air_chart.dart';
import '../widgets/nature_components.dart';
import '../widgets/primitives.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _days = 1;
  String _variable = 'us_aqi';
  Future<List<Map<String, Object?>>>? _notes;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final place = context.read<AirBloc>().state.place;
    if (place != null) {
      context.read<HistoryBloc>().add(LoadHistory(place, _days));
      _notes = context.read<LocalStore>().notes(place);
    }
  }

  Future<void> _openNotes() async {
    await context.push('/notes');
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => BlocListener<AirBloc, AirState>(
    listenWhen: (before, after) => !after.busy,
    listener: (_, _) => setState(_reload),
    child: Theme(
      data: AppTheme.create(Brightness.dark).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: AppTheme.create(Brightness.dark).textTheme
            .apply(fontFamily: 'Manrope'),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: Image.asset(
                    NatureStyle.forestMist,
                    fit: BoxFit.cover,
                    cacheWidth: 1000,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xa6163327),
                        Color(0x451c3825),
                        Color(0xd010281f),
                      ],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
              ),
              BackdropGroup(
                child: SafeArea(
                  bottom: false,
                  child: BlocBuilder<HistoryBloc, HistoryState>(
                    builder: (context, state) {
                      final report = context.watch<AirBloc>().state.report;
                      final place = context.watch<AirBloc>().state.place;
                      final offset = report?.utcOffsetSeconds ?? 0;
                      final points = state.place?.id == place?.id
                          ? state.points
                          : <AirPoint>[];
                      final values = points
                          .map((p) => p.values[_variable])
                          .whereType<double>()
                          .toList();
                      final average = AirAdvice.average(values);
                      final maximum = values.isEmpty
                          ? null
                          : values.reduce((a, b) => a > b ? a : b);
                      final validCount = values.length;
                      return RefreshIndicator(
                        onRefresh: () async {
                          if (place == null) return;
                          final bloc = context.read<HistoryBloc>();
                          final done = bloc.stream.firstWhere(
                            (s) => s.status != LoadStatus.loading,
                          );
                          setState(_reload);
                          await done;
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'История',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        place?.name ?? 'Сначала выберите город',
                                        style: const TextStyle(
                                          color: Color(0xffe0ebd9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Обновить историю',
                                  onPressed: place == null
                                      ? null
                                      : () => setState(_reload),
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            GlassSurface(
                              grouped: true,
                              padding: const EdgeInsets.all(5),
                              tint: const Color(0xff496044),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide =
                                      constraints.maxWidth > 320 ||
                                      MediaQuery.textScalerOf(context)
                                              .scale(12) <=
                                          15;
                                  final choices = [
                                    for (final days in [1, 7, 30])
                                      _PeriodButton(
                                        label: days == 1
                                            ? '24 часа'
                                            : '$days дней',
                                        selected: _days == days,
                                        onTap: () {
                                          setState(() {
                                            _days = days;
                                            _reload();
                                          });
                                        },
                                      ),
                                  ];
                                  return wide
                                      ? Row(
                                          children: choices
                                              .map((w) => Expanded(child: w))
                                              .toList(),
                                        )
                                      : Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: choices,
                                        );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final variable in [
                                  'us_aqi',
                                  'pm2_5',
                                  'pm10',
                                ])
                                  ChoiceChip(
                                    label: Text(
                                      variable == 'us_aqi'
                                          ? 'US AQI'
                                          : pollutantLabels[variable]!,
                                    ),
                                    showCheckmark: false,
                                    selected: _variable == variable,
                                    backgroundColor: const Color(0x55465940),
                                    selectedColor: const Color(0xffe3e9d8),
                                    labelStyle: TextStyle(
                                      color: _variable == variable
                                          ? NatureStyle.ink
                                          : Colors.white,
                                      fontSize: 12,
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: .2),
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _variable = variable),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GlassSurface(
                              grouped: true,
                              tint: const Color(0xff526146),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Динамика воздуха',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$validCount точек',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (state.status == LoadStatus.loading)
                                    const LinearProgressIndicator(minHeight: 2)
                                  else if (state.status == LoadStatus.error)
                                    _HistoryEmpty(
                                      icon: Icons.sync_problem_rounded,
                                      title: 'История недоступна',
                                      message:
                                          state.message ??
                                          'Повторите обновление.',
                                    )
                                  else if (place == null)
                                    const _HistoryEmpty(
                                      icon: Icons.place_outlined,
                                      title: 'Выберите город на главной',
                                      message: 'Здесь появятся сохранённые оценки воздуха.',
                                    )
                                  else if (validCount < 2)
                                    _HistoryEmpty(
                                      icon: Icons.timeline_rounded,
                                      title: validCount == 0
                                          ? 'История начинается здесь'
                                          : 'Первая точка уже сохранена',
                                      message: 'Для графика нужны две оценки. Открывайте приложение и обновляйте воздух — история будет накапливаться.',
                                    )
                                  else
                                    AirChart(
                                      points: points,
                                      variable: _variable,
                                      offsetSeconds: offset,
                                      gridColor: const Color(0xffe0ead9),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _Statistic(
                                    'Среднее',
                                    average,
                                    _variable,
                                    const Color(0xff66764d),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _Statistic(
                                    'Максимум',
                                    maximum,
                                    _variable,
                                    const Color(0xff354e40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GlassSurface(
                              grouped: true,
                              tint: const Color(0xff485f3c),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Календарь воздуха',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _Calendar(
                                    points: points,
                                    offsetSeconds: offset,
                                    today:
                                        report?.cityTime(
                                          DateTime.now().toUtc(),
                                        ) ??
                                        DateTime.now(),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Цвет — средний US AQI по сохранённым точкам.\nДни без данных не окрашены.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassSurface(
                              grouped: true,
                              tint: const Color(0xff324e40),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Записи воздуха',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.history_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (points.isEmpty)
                                    const Text(
                                      'Записей пока нет.',
                                      style: TextStyle(color: Colors.white70),
                                    )
                                  else
                                    ...points.reversed
                                        .take(48)
                                        .map(
                                          (p) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 9,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      p.band?.color ??
                                                          0xffb8c5b5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    '${dateLabel(p.time.add(Duration(seconds: offset)))} · ${clockLabel(p.time.add(Duration(seconds: offset)))}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  p.values[_variable]
                                                          ?.toStringAsFixed(
                                                            1,
                                                          ) ??
                                                      '—',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassSurface(
                              grouped: true,
                              tint: const Color(0xff526650),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Заметки о месте',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Открыть заметки',
                                        onPressed: place == null
                                            ? null
                                            : _openNotes,
                                        icon: const Icon(
                                          Icons.arrow_outward_rounded,
                                          size: 19,
                                        ),
                                      ),
                                    ],
                                  ),
                                  FutureBuilder<List<Map<String, Object?>>>(
                                    future: _notes,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return const Text(
                                          'Не удалось прочитать заметки. Откройте дневник и повторите.',
                                        );
                                      }
                                      final notes = snapshot.data ?? [];
                                      if (notes.isEmpty) {
                                        return const Text(
                                          'Ваши наблюдения дополнят историю воздуха.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return Column(
                                        children: notes
                                            .take(3)
                                            .map(
                                              (note) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(
                                                  note['image'] == null
                                                      ? Icons.edit_note_rounded
                                                      : Icons
                                                            .photo_camera_outlined,
                                                  size: 22,
                                                ),
                                                title: Text(
                                                  (note['text'] as String?)
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? note['text'] as String
                                                      : 'Фотография места',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  dateLabel(
                                                    DateTime.fromMillisecondsSinceEpoch(
                                                      note['created'] as int,
                                                    ).toLocal(),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                onTap: _openNotes,
                                              ),
                                            )
                                            .toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Open-Meteo / CAMS · сохранённые оценки модели. Средние рассчитаны по доступным точкам, а не по всему периоду. Прогноз не записывается как прошедшие измерения.',
                              style: TextStyle(
                                color: Color(0xffe0ebd9),
                                fontSize: 10,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      backgroundColor: selected ? NatureStyle.ink : Colors.transparent,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    onPressed: onTap,
    child: Text(label),
  );
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: NatureStyle.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Statistic extends StatelessWidget {
  const _Statistic(this.label, this.value, this.variable, this.tint);
  final String label, variable;
  final double? value;
  final Color tint;
  @override
  Widget build(BuildContext context) => GlassSurface(
    grouped: true,
    tint: tint,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          value?.toStringAsFixed(1) ?? '—',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          variable == 'us_aqi' ? 'US AQI' : 'мкг/м³',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    ),
  );
}

class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.points,
    required this.offsetSeconds,
    required this.today,
  });
  final List<AirPoint> points;
  final int offsetSeconds;
  final DateTime today;
  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<double>>{};
    final months = <int>{widget.today.year * 12 + widget.today.month - 1};
    for (final point in widget.points) {
      final time = point.time.add(Duration(seconds: widget.offsetSeconds));
      months.add(time.year * 12 + time.month - 1);
      if (point.aqi != null) {
        grouped
            .putIfAbsent(DateTime(time.year, time.month, time.day), () => [])
            .add(point.aqi!);
      }
    }
    final available = months.toList()..sort((a, b) => b.compareTo(a));
    final index = _index.clamp(0, available.length - 1);
    final month = DateTime(available[index] ~/ 12, available[index] % 12 + 1);
    const names = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${names[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Предыдущий месяц',
              onPressed: index + 1 < available.length
                  ? () => setState(() => _index = index + 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Следующий месяц',
              onPressed: index > 0
                  ? () => setState(() => _index = index - 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 6 * 6) / 7;
            final height =
                36.0 +
                (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24);
            final leading = month.weekday - 1;
            final count = DateTime(month.year, month.month + 1, 0).day;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final day in ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'])
                  SizedBox(
                    width: width,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                for (var i = 0; i < leading; i++)
                  SizedBox(width: width, height: height),
                for (var day = 1; day <= count; day++)
                  Builder(
                    builder: (context) {
                      final date = DateTime(month.year, month.month, day);
                      final values = grouped[date];
                      final aqi = values == null
                          ? null
                          : AirAdvice.average(values);
                      final today =
                          date.year == widget.today.year &&
                          date.month == widget.today.month &&
                          date.day == widget.today.day;
                      return Tooltip(
                        message: aqi == null
                            ? '${dateLabel(date)}: нет сохранённых данных'
                            : '${dateLabel(date)}: ${aqi.round()} US AQI, ${values!.length} точек',
                        child: Material(
                          color: aqi == null
                              ? Colors.white.withValues(alpha: .06)
                              : Color(AirBand.forAqi(aqi).color)
                                    .withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: aqi == null
                                ? null
                                : () => showDialog<void>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(dateLabel(date)),
                                      content: Text(
                                        '${aqi.toStringAsFixed(1)} US AQI · среднее по ${values!.length} сохранённым точкам.\n${AirBand.forAqi(aqi).label}',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Закрыть'),
                                        ),
                                      ],
                                    ),
                                  ),
                            child: Container(
                              width: width,
                              height: height,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: today
                                    ? Border.all(color: Colors.white70)
                                    : null,
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: aqi == null
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                  color: aqi == null
                                      ? Colors.white60
                                      : Color(AirBand.forAqi(aqi).color)
                                                .computeLuminance() >
                                            .3
                                      ? NatureStyle.ink
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
