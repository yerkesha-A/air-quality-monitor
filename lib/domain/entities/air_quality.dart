enum AirBand {
  good('Хороший', 0xffa8bc87),
  moderate('Умеренный', 0xffdbc67b),
  sensitive('Вреден для чувствительных групп', 0xffd6a075),
  unhealthy('Вредный', 0xffcb8274),
  veryUnhealthy('Очень вредный', 0xffaa88a4),
  hazardous('Опасный', 0xff956b76);

  const AirBand(this.label, this.color);
  final String label;
  final int color;

  static AirBand forAqi(double aqi) {
    if (!aqi.isFinite || aqi < 0) throw ArgumentError.value(aqi, 'aqi');
    if (aqi <= 50) return good;
    if (aqi <= 100) return moderate;
    if (aqi <= 150) return sensitive;
    if (aqi <= 200) return unhealthy;
    if (aqi <= 300) return veryUnhealthy;
    return hazardous;
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.region = '',
  });
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String region;
  String get subtitle =>
      [region, country].where((s) => s.isNotEmpty).join(', ');
}

class AirPoint {
  AirPoint({required this.time, required Map<String, double?> values})
    : values = Map.unmodifiable(values);
  final DateTime time;
  final Map<String, double?> values;
  double? get aqi => values['us_aqi'];
  AirBand? get band => aqi == null ? null : AirBand.forAqi(aqi!);
}

class AirReport {
  AirReport({
    required this.place,
    required this.current,
    required List<AirPoint> forecast,
    required this.fetchedAt,
    this.utcOffsetSeconds = 0,
    this.offline = false,
  }) : forecast = List.unmodifiable(forecast);
  final Place place;
  final AirPoint current;
  final List<AirPoint> forecast;
  final DateTime fetchedAt;
  final int utcOffsetSeconds;
  final bool offline;
  bool isStale(DateTime now) =>
      now.difference(fetchedAt) > const Duration(hours: 1);
  DateTime cityTime(DateTime utc) =>
      utc.toUtc().add(Duration(seconds: utcOffsetSeconds));
  AirReport asOffline() => AirReport(
    place: place,
    current: current,
    forecast: forecast,
    fetchedAt: fetchedAt,
    utcOffsetSeconds: utcOffsetSeconds,
    offline: true,
  );
  List<AirPoint> upcoming(DateTime now) => forecast
      .where(
        (p) =>
            !p.time.isBefore(now) &&
            p.time.isBefore(now.add(const Duration(hours: 24))),
      )
      .toList();
}

const pollutantLabels = <String, String>{
  'pm2_5': 'PM₂.₅',
  'pm10': 'PM₁₀',
  'nitrogen_dioxide': 'NO₂',
  'ozone': 'O₃',
  'carbon_monoxide': 'CO',
  'sulphur_dioxide': 'SO₂',
};
