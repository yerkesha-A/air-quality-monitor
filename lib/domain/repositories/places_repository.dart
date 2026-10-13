import '../entities/air_quality.dart';

abstract interface class PlacesRepository {
  Future<Place?> selected();
  Future<void> select(Place place);
  Future<List<Place>> recent();
  Future<List<Place>> favorites();
  Future<void> setFavorite(Place place, bool favorite);
}
