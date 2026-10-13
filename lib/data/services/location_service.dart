import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';

class LocationService {
  Future<Place> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AirFailure('Включите геолокацию в настройках Android.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AirFailure(
        'Доступ к геолокации запрещён. Разрешите его в настройках приложения Android.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const AirFailure(
        'Доступ к геолокации не предоставлен. Можно выбрать город вручную.',
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 25),
        ),
      );
      var name = 'Моё местоположение';
      var country = '';
      try {
        final addresses = await Geocoding()
            .placemarkFromCoordinates(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 8));
        if (addresses.isNotEmpty) {
          final address = addresses.first;
          name = address.locality?.isNotEmpty == true
              ? address.locality!
              : name;
          country = address.country ?? '';
        }
      } catch (_) {
        /* Coordinates remain usable when reverse geocoding is unavailable. */
      }
      return Place(
        id: 'gps:${position.latitude.toStringAsFixed(3)},${position.longitude.toStringAsFixed(3)}',
        name: name,
        latitude: position.latitude,
        longitude: position.longitude,
        country: country,
      );
    } catch (_) {
      throw const AirFailure(
        'Не удалось определить местоположение. Повторите запрос или выберите город.',
      );
    }
  }
}
