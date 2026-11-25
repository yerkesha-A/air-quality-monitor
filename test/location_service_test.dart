import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';

class _Geo extends Mock implements GeolocatorPlatform {}

void main() {
  late _Geo geo;
  setUpAll(() => registerFallbackValue(const LocationSettings()));
  setUp(() {
    geo = _Geo();
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
  });
  Future<void> issue(LocationService service, LocationIssue issue) =>
      expectLater(
        service.locate(),
        throwsA(isA<LocationFailure>().having((f) => f.issue, 'issue', issue)),
      );
  test('Disabled service does not request permission or position', () async {
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => false);
    await issue(LocationService(platformOverride: geo), LocationIssue.disabled);
    verifyNever(() => geo.requestPermission());
    verifyNever(
      () => geo.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      ),
    );
  });
  test('Denied request and permanently denied remain distinct without permission loops', () async {
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.denied);
    when(() => geo.requestPermission())
        .thenAnswer((_) async => LocationPermission.denied);
    await issue(LocationService(platformOverride: geo), LocationIssue.denied);
    verify(() => geo.requestPermission()).called(1);
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.deniedForever);
    await issue(
      LocationService(platformOverride: geo),
      LocationIssue.permanentlyDenied,
    );
    verifyNever(() => geo.requestPermission());
  });
  test('Real coordinates survive reverse-geocoding failure; allowed permission is not requested again', () async {
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      () => geo.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      ),
    ).thenAnswer(
      (_) async => Position(
        latitude: 43.25,
        longitude: 76.95,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    final service = LocationService(
      platformOverride: geo,
      reverseGeocode: (_, _) async => throw StateError('no geocoder'),
    );
    final place = await service.locate();
    expect(place.latitude, 43.25);
    expect(place.longitude, 76.95);
    expect(place.name, 'Моё местоположение');
    verifyNever(() => geo.requestPermission());
    expect(await service.hasPermission(), isTrue);
  });
  test(
    'iOS requests foreground Apple location settings with a timeout',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => geo.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(StateError('test stop after settings capture'));
      await issue(
        LocationService(platformOverride: geo),
        LocationIssue.unavailable,
      );
      final settings =
          verify(
                () => geo.getCurrentPosition(
                  locationSettings: captureAny(named: 'locationSettings'),
                ),
              ).captured.single
              as LocationSettings;
      expect(settings, isA<AppleSettings>());
      expect(settings.timeLimit, const Duration(seconds: 25));
    },
  );
  test(
    'Settings use correct Android target; plugin failures are controlled',
    () async {
      when(() => geo.openLocationSettings()).thenAnswer((_) async => true);
      when(() => geo.openAppSettings()).thenAnswer((_) async => false);
      final s = LocationService(platformOverride: geo);
      expect(await s.openSettings(LocationIssue.disabled), isTrue);
      expect(await s.openSettings(LocationIssue.permanentlyDenied), isFalse);
      when(() => geo.checkPermission())
          .thenThrow(StateError('platform unavailable'));
      expect(await s.hasPermission(), isFalse);
      await issue(s, LocationIssue.unavailable);
    },
  );
}
