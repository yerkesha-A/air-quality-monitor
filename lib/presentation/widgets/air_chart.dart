import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/air_quality.dart';
import 'primitives.dart';

class AirChart extends StatefulWidget {
  const AirChart({
    super.key,
    required this.points,
    this.variable = 'us_aqi',
    this.offsetSeconds = 0,
  });
  final List<AirPoint> points;
  final String variable;
  final int offsetSeconds;
  @override
  State<AirChart> createState() => _AirChartState();
}

class _AirChartState extends State<AirChart> {
  int? _selected;
  @override
  void didUpdateWidget(AirChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.where((p) => p.values[widget.variable] != null).length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Для графика нужны хотя бы две доступные точки. Данные пока накапливаются.',
        ),
      );
    }
    final color = Theme.of(context).colorScheme.primary;
    final selected = _selected == null ? null : points[_selected!];
    final first = points.first.time;
    final last = points.last.time;
    final duration = math.max(1, last.difference(first).inMilliseconds);
    final offset = Duration(seconds: widget.offsetSeconds);
    return Semantics(
      label:
          '${widget.variable == 'us_aqi' ? 'US AQI' : pollutantLabels[widget.variable]}. График ${points.length} точек.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: selected == null
                ? const Text('Коснитесь графика, чтобы увидеть значение')
                : Text(
                    '${dateLabel(selected.time.add(offset))} ${clockLabel(selected.time.add(offset))}  ·  ${selected.values[widget.variable]?.toStringAsFixed(1) ?? 'нет данных'} ${widget.variable == 'us_aqi' ? 'US AQI' : 'мкг/м³'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          SizedBox(
            height: 156,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapDown: (details) => _select(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  first,
                  duration,
                ),
                onHorizontalDragUpdate: (details) => _select(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  first,
                  duration,
                ),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 156),
                  painter: _AirChartPainter(
                    points,
                    widget.variable,
                    color,
                    Theme.of(context).colorScheme.outlineVariant,
                    _selected,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clockLabel(first.add(offset))),
              Text(clockLabel(last.add(offset))),
            ],
          ),
        ],
      ),
    );
  }

  void _select(double x, double width, DateTime first, int duration) {
    final fraction = (x / width).clamp(0.0, 1.0);
    final target = first.millisecondsSinceEpoch + fraction * duration;
    var index = 0;
    var distance = double.infinity;
    for (var i = 0; i < widget.points.length; i++) {
      final d = (widget.points[i].time.millisecondsSinceEpoch - target).abs();
      if (d < distance) {
        distance = d;
        index = i;
      }
    }
    setState(() => _selected = index);
  }
}

class _AirChartPainter extends CustomPainter {
  _AirChartPainter(
    this.points,
    this.variable,
    this.color,
    this.grid,
    this.selected,
  );
  final List<AirPoint> points;
  final String variable;
  final Color color;
  final Color grid;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((p) => p.values[variable])
        .whereType<double>()
        .toList();
    final maximum = math.max(
      variable == 'us_aqi' ? 50.0 : 1.0,
      values.reduce(math.max) * 1.15,
    );
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      final y = 12 + (size.height - 24) * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final text = TextPainter(
        text: TextSpan(
          text: (maximum * (1 - row / 3)).round().toString(),
          style: TextStyle(color: grid, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - 12));
    }
    final duration = math.max(
      1,
      points.last.time.difference(points.first.time).inMilliseconds,
    );
    final path = Path();
    var connected = false;
    for (var i = 0; i < points.length; i++) {
      final value = points[i].values[variable];
      if (value == null) {
        connected = false;
        continue;
      }
      final x =
          size.width *
          points[i].time.difference(points.first.time).inMilliseconds /
          duration;
      final y = 12 + (size.height - 24) * (1 - value / maximum);
      if (!connected) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      connected = true;
      if (i == selected) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_AirChartPainter oldDelegate) => true;
}
