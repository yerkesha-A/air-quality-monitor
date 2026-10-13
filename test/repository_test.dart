import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/models/air_dto.dart';
import 'package:air_quality_monitor/data/remote/open_meteo_api.dart';
import 'package:air_quality_monitor/data/repositories/open_meteo_repository.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'api_test.dart' show validPayload, testPlace;
import 'support/test_dependencies.dart' show fixtureReport;

class MockApi extends Mock implements OpenMeteoApi {}

class MockStore extends Mock implements LocalStore {}

class MockLocation extends Mock implements LocationService {}

void main() {
  late MockApi api;
  late MockStore store;
  late MockLocation location;
  late OpenMeteoRepository repository;
  setUp(() {
    api = MockApi();
    store = MockStore();
    location = MockLocation();
    registerFallbackValue(testPlace);
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(const AirPayloadDto());
    repository = OpenMeteoRepository(
      api: api,
      store: store,
      location: location,
    );
  });
  test(
    'Online result is persisted only after valid current AQI exists',
    () async {
      when(() => api.air(testPlace))
          .thenAnswer((_) async => AirPayloadDto.fromJson(validPayload()));
      when(() => store.save(testPlace, any(), any())).thenAnswer((_) async {});
      final result = await repository.fetch(testPlace);
      expect(result.current.aqi, 42);
      expect(result.offline, isFalse);
      verify(() => store.save(testPlace, any(), any())).called(1);
    },
  );
  test(
    'Network failure returns original cache timestamp and offline flag',
    () async {
      final saved = fixtureReport();
      when(() => api.air(testPlace)).thenThrow(const AirFailure('Offline'));
      when(() => store.cached(testPlace)).thenAnswer((_) async => saved);
      final result = await repository.fetch(testPlace);
      expect(result.offline, isTrue);
      expect(result.fetchedAt, saved.fetchedAt);
      verifyNever(() => store.save(testPlace, any(), any()));
    },
  );
  test(
    'No cache means error, and missing AQI never becomes a saved sample',
    () async {
      when(() => api.air(testPlace))
          .thenAnswer((_) async => const AirPayloadDto());
      when(() => store.cached(testPlace)).thenAnswer((_) async => null);
      await expectLater(repository.fetch(testPlace), throwsA(isA<AirEmpty>()));
      verifyNever(() => store.save(testPlace, any(), any()));
    },
  );
  test('Search, GPS, cache and history use their respective sources', () async {
    when(() => api.search('Алматы')).thenAnswer((_) async => [testPlace]);
    when(() => location.locate()).thenAnswer((_) async => testPlace);
    when(() => store.cached(testPlace))
        .thenAnswer((_) async => fixtureReport());
    when(() => store.history(testPlace, 7)).thenAnswer((_) async => []);
    expect((await repository.search('Алматы')).single.id, testPlace.id);
    expect((await repository.locate()).id, testPlace.id);
    expect(await repository.cached(testPlace), isNotNull);
    expect(await repository.history(testPlace, 7), isEmpty);
  });
}
