import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/places_repository.dart';
import '../local/local_store.dart';
import '../models/air_dto.dart';

class LocalPlacesRepository implements PlacesRepository {
  LocalPlacesRepository(this.store, this.preferences);
  final LocalStore store;
  final SharedPreferences preferences;
  @override
  Future<Place?> selected() async {
    final value = preferences.getString('selected_place');
    if (value == null) return null;
    try {
      return PlaceDto.fromJson(jsonDecode(value) as Map<String, dynamic>)
          .toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> select(Place place) async {
    await preferences.setString(
      'selected_place',
      jsonEncode(PlaceDto.fromEntity(place).toJson()),
    );
    await store.remember(place);
  }

  @override
  Future<List<Place>> recent() => store.places();
  @override
  Future<List<Place>> favorites() => store.places(favoritesOnly: true);
  @override
  Future<void> setFavorite(Place place, bool favorite) =>
      store.favorite(place, favorite);
}
