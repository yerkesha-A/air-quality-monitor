import '../entities/air_quality.dart';

class AirAdvice {
  static String summary(double? aqi) {
    if (aqi == null) {
      return 'Данных пока нет. Выберите город и обновите показатель.';
    }
    return switch (AirBand.forAqi(aqi)) {
      AirBand.good => 'Хороший день для прогулки. Выберите маршрут подальше от оживлённых дорог.',
      AirBand.moderate => 'Обычная прогулка возможна. Если вы чувствительны к загрязнению, следите за самочувствием.',
      AirBand.sensitive => 'Чувствительным людям лучше сократить длительные и интенсивные нагрузки на улице.',
      AirBand.unhealthy => 'Сократите нагрузку на улице. Для тренировки сегодня лучше выбрать помещение.',
      AirBand.veryUnhealthy => 'Избегайте интенсивных нагрузок на улице. Чувствительным людям лучше оставаться в помещении.',
      AirBand.hazardous => 'Избегайте активности на улице и следуйте местным предупреждениям о загрязнении.',
    };
  }

  static String activity(double? aqi, {bool intense = false}) {
    if (aqi == null) return 'Нужны данные';
    if (aqi > 150) return 'Лучше в помещении';
    if (aqi > 100 || (intense && aqi > 50)) return 'Снизьте нагрузку';
    return 'Подходящие условия';
  }

  static AirPoint? bestHour(List<AirPoint> points) {
    final available = points.where((p) => p.aqi != null).toList();
    if (available.isEmpty) return null;
    available.sort((a, b) => a.aqi!.compareTo(b.aqi!));
    return available.first;
  }

  static double? average(Iterable<double?> values) {
    final valid = values.whereType<double>().where((v) => v.isFinite).toList();
    return valid.isEmpty ? null : valid.reduce((a, b) => a + b) / valid.length;
  }
}
