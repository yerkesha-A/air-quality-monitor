import '../entities/air_quality.dart';

abstract interface class AirRepository {
  Future<AirReport?> cached(Place place);
  Future<AirReport> fetch(Place place);
  Future<List<Place>> search(String query);
  Future<Place> resolve(String id);
  Future<List<AirPoint>> history(Place place, int days);
  Future<Place> locate();
}

class AirFailure implements Exception {
  const AirFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AirEmpty extends AirFailure {
  const AirEmpty(super.message);
}
