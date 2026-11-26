import 'package:flutter/material.dart';

import '../../domain/entities/air_quality.dart';
import 'nature_components.dart';
import 'primitives.dart';

class NotificationHistoryHeading extends StatelessWidget {
  const NotificationHistoryHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Column(
        children: [
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'История уведомлений',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationHistoryEmpty extends StatelessWidget {
  const NotificationHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AirSurface(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Пока нет уведомлений',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Предупреждения о качестве воздуха будут сохраняться здесь.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation of existing local/FCM records; no schema migration or writes.
/// Only the known leading measurement is parsed. Unstructured messages retain
/// their full text and a neutral icon instead of an invented AQI/category.
class NotificationHistoryCard extends StatelessWidget {
  const NotificationHistoryCard({super.key, required this.record});

  final Map<String, Object?> record;
  static final _measurement = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s+US\s+AQI\b',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final title = (record['title'] as String? ?? '').trim();
    final body = (record['body'] as String? ?? '').trim();
    final match = _measurement.firstMatch(body);
    final parsed = match == null
        ? null
        : double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final aqi = parsed != null && parsed.isFinite ? parsed : null;
    final band = aqi == null ? null : AirBand.forAqi(aqi);
    final accent = band == null ? theme.colorScheme.primary : Color(band.color);
    // Deepened category ink in light mode keeps the muted AQI palette legible.
    final ink = dark
        ? Color.lerp(accent, Colors.white, .30)!
        : Color.lerp(accent, Colors.black, .55)!;
    final city = title.startsWith('Воздух в ')
        ? title.substring('Воздух в '.length).trim()
        : title;
    final detail = aqi == null
        ? body
        : body.substring(match!.end).replaceFirst(RegExp(r'^[\s—–:,-]+'), '');
    final message = detail.isEmpty
        ? ''
        : '${detail[0].toUpperCase()}${detail.substring(1)}';
    final millis = record['created'];
    final created = millis is int
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AirSurface(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: dark ? .18 : .23),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    band == null
                        ? Icons.notifications_outlined
                        : Icons.warning_amber_rounded,
                    color: ink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.isEmpty ? 'Уведомление' : city,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      if (aqi != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: dark ? .18 : .23,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${aqi.round()} US AQI',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              band!.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (created != null) ...[
              const SizedBox(height: 16),
              DefaultTextStyle(
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined),
                          const SizedBox(width: 6),
                          Text(dateLabel(created)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded),
                          const SizedBox(width: 6),
                          Text(clockLabel(created)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
