import 'package:flutter/foundation.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';

enum LocationIssue { disabled, denied, permanentlyDenied, unavailable }

class LocationFailure extends AirFailure {
  const LocationFailure(this.issue, super.message);
  final LocationIssue issue;
}

class LocationService {
  LocationService({this.platformOverride, this.reverseGeocode});
  final GeolocatorPlatform? platformOverride;
  final Future<List<Placemark>> Function(double, double)? reverseGeocode;
  GeolocatorPlatform get platform =>
      platformOverride ?? GeolocatorPlatform.instance;

  Future<Place> locate() async {
    try {
      if (!await platform.isLocationServiceEnabled()) {
        throw const LocationFailure(
          LocationIssue.disabled,
          'Включите геолокацию в настройках устройства.',
        );
      }
      var permission = await platform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await platform.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          LocationIssue.permanentlyDenied,
          'Доступ к геолокации запрещён. Разрешите его в настройках приложения.',
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const LocationFailure(
          LocationIssue.denied,
          'Доступ к геолокации не предоставлен. Можно выбрать город вручную.',
        );
      }
      final position = await platform
          .getCurrentPosition(
            locationSettings: defaultTargetPlatform == TargetPlatform.iOS
                ? AppleSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: const Duration(seconds: 25),
                    pauseLocationUpdatesAutomatically: true,
                  )
                : AndroidSettings(
                    accuracy: LocationAccuracy.high,
                    forceLocationManager: true,
                    timeLimit: const Duration(seconds: 25),
                  ),
          )
          .timeout(const Duration(seconds: 25));
      var name = 'Моё местоположение';
      var country = '';
      try {
        final addresses =
            await (reverseGeocode?.call(
                      position.latitude,
                      position.longitude,
                    ) ??
                    Geocoding().placemarkFromCoordinates(
                      position.latitude,
                      position.longitude,
                    ))
                .timeout(const Duration(seconds: 8));
        if (addresses.isNotEmpty) {
          final address = addresses.first;
          if (address.locality?.isNotEmpty == true) name = address.locality!;
          country = address.country ?? '';
        }
      } catch (_) {
        /* Coordinates are valid even without a reverse-geocoding service. */
      }
      return Place(
        id: 'gps:${position.latitude.toStringAsFixed(3)},${position.longitude.toStringAsFixed(3)}',
        name: name,
        latitude: position.latitude,
        longitude: position.longitude,
        country: country,
      );
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(
        LocationIssue.unavailable,
        'Не удалось определить местоположение. Повторите запрос или выберите город.',
      );
    }
  }

  Future<bool> serviceEnabled() async {
    try {
      return await platform.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      final p = await platform.checkPermission();
      return p == LocationPermission.whileInUse ||
          p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSettings(LocationIssue issue) async {
    try {
      return issue == LocationIssue.disabled
          ? await platform.openLocationSettings()
          : await platform.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
