import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/repositories/firebase_auth_repository.dart';
import 'package:air_quality_monitor/data/services/firebase_service.dart';
import 'package:air_quality_monitor/data/services/notification_service.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:air_quality_monitor/domain/repositories/places_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAirRepository extends Mock implements AirRepository {}

class MockPlacesRepository extends Mock implements PlacesRepository {}

class MockLocalStore extends Mock implements LocalStore {}

class MockNotifications extends Mock implements NotificationService {
  @override
  void Function(String route)? onOpen;
  @override
  String? initialRoute;
}

const fixturePlace = Place(
  id: '1526384',
  name: 'Алматы',
  latitude: 43.25249,
  longitude: 76.9115,
  country: 'Казахстан',
);
AirReport fixtureReport() {
  final now = DateTime.now().toUtc();
  return AirReport(
    place: fixturePlace,
    current: AirPoint(
      time: now,
      values: {
        'us_aqi': 42,
        'pm2_5': 8.5,
        'pm10': 14.2,
        'ozone': 30,
        'nitrogen_dioxide': 12,
        'carbon_monoxide': 200,
        'sulphur_dioxide': 5,
      },
    ),
    forecast: List.generate(
      24,
      (index) => AirPoint(
        time: now.add(Duration(hours: index)),
        values: {
          'us_aqi': 40.0 + index,
          'pm2_5': 8.0 + index,
          'pm10': 12.0 + index,
        },
      ),
    ),
    fetchedAt: now,
    utcOffsetSeconds: 18000,
  );
}

AppDependencies testDependencies({bool selected = false}) {
  registerFallbackValue(fixturePlace);
  registerFallbackValue(fixtureReport());
  final air = MockAirRepository();
  final places = MockPlacesRepository();
  final store = MockLocalStore();
  final notifications = MockNotifications();
  when(() => places.selected())
      .thenAnswer((_) async => selected ? fixturePlace : null);
  when(() => places.recent()).thenAnswer((_) async => []);
  when(() => places.favorites()).thenAnswer((_) async => []);
  when(() => places.select(any())).thenAnswer((_) async {});
  when(() => places.setFavorite(any(), any())).thenAnswer((_) async {});
  when(() => air.cached(any())).thenAnswer((_) async => null);
  when(() => air.fetch(any())).thenAnswer((_) async => fixtureReport());
  when(() => air.search(any())).thenAnswer((_) async => [fixturePlace]);
  when(() => air.resolve(any())).thenAnswer((_) async => fixturePlace);
  when(() => air.history(any(), any()))
      .thenAnswer((_) async => [fixtureReport().current]);
  when(() => store.alerts()).thenAnswer((_) async => []);
  when(() => store.notes(any())).thenAnswer((_) async => []);
  when(
    () => notifications.check(
      any(),
      enabled: any(named: 'enabled'),
      threshold: any(named: 'threshold'),
    ),
  ).thenAnswer((_) async {});
  when(() => notifications.requestPermission()).thenAnswer((_) async => true);
  return AppDependencies(
    air: air,
    places: places,
    store: store,
    auth: FirebaseAuthRepository(),
    firebase: FirebaseService(configured: false),
    notifications: notifications,
  );
}
