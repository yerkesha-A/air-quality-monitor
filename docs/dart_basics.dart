/// Неделя 1: null safety, коллекции и Future.
Future<void> main() async {
  const cities = <String>['Алматы', 'Астана', 'Шымкент'];
  final String? selectedCity = cities.isEmpty ? null : cities.first;
  final matches = cities.where((city) => city.startsWith('А')).toList();
  final label = await Future<String>.value(selectedCity ?? 'Город не выбран');
  assert(matches.length == 2);
  assert(label == 'Алматы');
  // ignore: avoid_print
  print('Null safety, коллекции и Future: $label; ${matches.join(', ')}');
}
