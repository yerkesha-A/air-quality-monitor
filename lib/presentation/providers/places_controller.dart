import 'package:flutter/foundation.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/places_repository.dart';

class PlacesController extends ChangeNotifier {
  PlacesController(this.repository);
  final PlacesRepository repository;
  List<Place> favorites = [];
  List<Place> recent = [];
  bool isFavorite(Place place) => favorites.any((p) => p.id == place.id);
  Future<void> reload() async {
    favorites = await repository.favorites();
    recent = await repository.recent();
    notifyListeners();
  }

  Future<void> toggle(Place place) async {
    await repository.setFavorite(place, !isFavorite(place));
    await reload();
  }
}
