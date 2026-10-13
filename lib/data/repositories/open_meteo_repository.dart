import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../local/local_store.dart';
import '../remote/open_meteo_api.dart';
import '../services/location_service.dart';

class OpenMeteoRepository implements AirRepository {
  OpenMeteoRepository({
    required this.api,
    required this.store,
    required this.location,
  });
  final OpenMeteoApi api;
  final LocalStore store;
  final LocationService location;
  @override
  Future<AirReport?> cached(Place place) => store.cached(place);
  @override
  Future<AirReport> fetch(Place place) async {
    try {
      final dto = await api.air(place);
      final now = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      );
      final report = dto.toEntity(place, now);
      if (report == null) {
        throw const AirEmpty(
          'Для выбранного места источник не предоставил текущий AQI.',
        );
      }
      await store.save(place, dto, now);
      return report;
    } on AirFailure {
      final saved = await cached(place);
      if (saved != null) return saved.asOffline();
      rethrow;
    }
  }

  @override
  Future<List<Place>> search(String query) => api.search(query);
  @override
  Future<Place> resolve(String id) => api.resolve(id);
  @override
  Future<List<AirPoint>> history(Place place, int days) =>
      store.history(place, days);
  @override
  Future<Place> locate() => location.locate();
}
