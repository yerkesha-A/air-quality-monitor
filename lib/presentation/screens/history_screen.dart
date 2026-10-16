import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/local_store.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/usecases/air_advice.dart';
import '../bloc/air_bloc.dart';
import '../bloc/history_bloc.dart';
import '../widgets/air_chart.dart';
import '../widgets/nature_components.dart';
import '../widgets/primitives.dart';
import '../widgets/paged_records.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _days = 1;
  int _revision = 0;
  String _variable = 'us_aqi';
  Future<List<Map<String, Object?>>>? _notes;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _revision++;
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
    child: AirScaffold(
      photographic: true,
      body: SafeArea(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                        icon: Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AirSurface(
                    padding: const EdgeInsets.all(5),
                    accent: NatureStyle.mint,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth > 320 ||
                            MediaQuery.textScalerOf(context).scale(12) <= 15;
                        final choices = [
                          for (final days in [1, 7, 30])
                            _PeriodButton(
                              label: days == 1 ? '24 часа' : '$days дней',
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
                      for (final variable in ['us_aqi', 'pm2_5', 'pm10'])
                        ChoiceChip(
                          label: Text(
                            variable == 'us_aqi'
                                ? 'US AQI'
                                : pollutantLabels[variable]!,
                          ),
                          showCheckmark: false,
                          selected: _variable == variable,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                  AirSurface(
                    accent: NatureStyle.mint,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Динамика воздуха',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              pointCountLabel(validCount),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                            message: state.message ?? 'Повторите обновление.',
                          )
                        else if (place == null)
                          const _HistoryEmpty(
                            icon: Icons.place_outlined,
                            title: 'Выберите город на главной',
                            message:
                                'Здесь появятся сохранённые оценки воздуха.',
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
                          const Color(0xff688d9d),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Statistic(
                          'Максимум',
                          maximum,
                          _variable,
                          const Color(0xff325c72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AirSurface(
                    accent: NatureStyle.mint,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                              report?.cityTime(DateTime.now().toUtc()) ??
                              DateTime.now(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Цвет — средний US AQI по сохранённым точкам.\nДни без данных не окрашены.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AirSurface(
                    accent: NatureStyle.mint,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Записи воздуха',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.history_rounded, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (points.isEmpty)
                          Text(
                            'Записей пока нет.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          )
                        else
                          PagedRecords<AirPoint>(
                            key: ValueKey('${place?.id}:$_days:$_revision'),
                            load: (after) => context
                                .read<LocalStore>()
                                .historyPage(place!, _days, after: after),
                            itemBuilder: (p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Color(p.band?.color ?? 0xffb8c5b5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${dateLabel(p.time.add(Duration(seconds: offset)))} · ${clockLabel(p.time.add(Duration(seconds: offset)))}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.values[_variable]?.toStringAsFixed(1) ??
                                        '—',
                                    style: TextStyle(
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
                  AirSurface(
                    accent: NatureStyle.mint,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
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
                              onPressed: place == null ? null : _openNotes,
                              icon: Icon(Icons.arrow_outward_rounded, size: 19),
                            ),
                          ],
                        ),
                        FutureBuilder<List<Map<String, Object?>>>(
                          future: _notes,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Не удалось прочитать заметки. Откройте дневник и повторите.',
                              );
                            }
                            final notes = snapshot.data ?? [];
                            if (notes.isEmpty) {
                              return Text(
                                'Ваши наблюдения дополнят историю воздуха.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                                            : Icons.photo_camera_outlined,
                                        size: 22,
                                      ),
                                      title: Text(
                                        (note['text'] as String?)?.isNotEmpty ==
                                                true
                                            ? note['text'] as String
                                            : 'Фотография места',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      subtitle: Text(
                                        dateLabel(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            note['created'] as int,
                                          ).toLocal(),
                                        ),
                                        style: TextStyle(fontSize: 10),
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
                  Text(
                    'Open-Meteo / CAMS · сохранённые оценки модели. Средние рассчитаны по доступным точкам, а не по всему периоду. Прогноз не записывается как прошедшие измерения.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primary
          : Colors.transparent,
      foregroundColor: selected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  Widget build(BuildContext context) => AirSurface(
    accent: NatureStyle.mint,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value?.toStringAsFixed(1) ?? '—',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          variable == 'us_aqi' ? 'US AQI' : 'мкг/м³',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Предыдущий месяц',
              onPressed: index + 1 < available.length
                  ? () => setState(() => _index = index + 1)
                  : null,
              icon: Icon(Icons.chevron_left_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Следующий месяц',
              onPressed: index > 0
                  ? () => setState(() => _index = index - 1)
                  : null,
              icon: Icon(Icons.chevron_right_rounded, size: 18),
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
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            : '${dateLabel(date)}: ${aqi.round()} US AQI, ${pointCountLabel(values!.length)}',
                        child: Material(
                          color: aqi == null
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
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
                                          child: Text('Закрыть'),
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
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      )
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
                                      ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
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
