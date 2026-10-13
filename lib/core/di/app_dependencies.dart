import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/local_store.dart';
import '../../data/remote/open_meteo_api.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/local_places_repository.dart';
import '../../data/repositories/open_meteo_repository.dart';
import '../../data/services/device_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/repositories/air_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/places_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.air,
    required this.places,
    required this.store,
    required this.auth,
    required this.firebase,
    required this.notifications,
  });
  final AirRepository air;
  final PlacesRepository places;
  final LocalStore store;
  final AuthRepository auth;
  final FirebaseService firebase;
  final NotificationService notifications;
  static Future<AppDependencies> create(SharedPreferences preferences) async {
    final store = await LocalStore.open();
    final device = await DeviceService().info();
    final firebase = await FirebaseService.create(
      device['firebaseConfigured'] == true,
    );
    final notifications = NotificationService(store, preferences);
    await notifications.initialize();
    await firebase.start(notifications);
    return AppDependencies(
      air: OpenMeteoRepository(
        api: OpenMeteoApi(http.Client()),
        store: store,
        location: LocationService(),
      ),
      places: LocalPlacesRepository(store, preferences),
      store: store,
      auth: FirebaseAuthRepository(
        auth: firebase.configured ? FirebaseAuth.instance : null,
        storage: firebase.configured ? FirebaseStorage.instance : null,
        googleClientId: device['googleClientId'] as String? ?? '',
      ),
      firebase: firebase,
      notifications: notifications,
    );
  }
}
