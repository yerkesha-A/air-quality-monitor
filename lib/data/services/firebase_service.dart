import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/local_store.dart';
import '../models/air_dto.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  final store = await LocalStore.open();
  try {
    await store.recordAlert(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Качество воздуха',
      body: message.notification?.body ?? '',
      source: 'push',
    );
  } finally {
    await store.database.close();
  }
}

class FirebaseService {
  FirebaseService({required this.configured, this.schedulerConfigured = false});
  final bool configured;
  final bool schedulerConfigured;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokens;
  String? initialRoute;
  void Function(String route)? onOpen;
  static Future<FirebaseService> create(bool nativeConfigured) async {
    if (!nativeConfigured) return FirebaseService(configured: false);
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessage);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
    if (kReleaseMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
    return FirebaseService(
      configured: true,
      schedulerConfigured: const bool.fromEnvironment('AQI_SCHEDULER_DEPLOYED'),
    );
  }

  Future<void> start(NotificationService notifications) async {
    if (!configured) return;
    _foreground = FirebaseMessaging.onMessage.listen((message) async {
      await notifications.show(
        id:
            message.messageId ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Качество воздуха',
        body: message.notification?.body ?? '',
        source: 'push',
      );
    });
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onOpen?.call('/alerts'),
    );
    if (await FirebaseMessaging.instance.getInitialMessage() != null) {
      initialRoute = '/alerts';
    }
    _tokens = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await _saveToken(uid, token);
    });
  }

  Future<bool> enablePush(Account account) async {
    if (!configured) return false;
    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(account.id, token);
    return token != null;
  }

  Future<void> _saveToken(String uid, String token) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc(Uri.encodeComponent(token))
      .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> unregisterDevice() async {
    if (!configured) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = await FirebaseMessaging.instance.getToken();
    if (uid != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(Uri.encodeComponent(token))
          .delete();
    }
  }

  Future<void> sync({
    required Account account,
    required Place? place,
    required List<Place> favorites,
    required int threshold,
    required bool backgroundAlerts,
    required int theme,
    required bool milligrams,
  }) async {
    if (!configured || FirebaseAuth.instance.currentUser?.uid != account.id) {
      return;
    }
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(account.id);
    await ref.set({
      'name': account.name,
      'email': account.email,
      'photoUrl': account.photoUrl,
      'threshold': threshold,
      'backgroundAlerts': backgroundAlerts,
      'place': place == null ? null : PlaceDto.fromEntity(place).toJson(),
      'theme': theme,
      'milligrams': milligrams,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final existing = await ref.collection('favorites').get();
    final batch = db.batch();
    final ids = favorites.map((p) => p.id).toSet();
    for (final doc in existing.docs) {
      if (!ids.contains(doc.id)) batch.delete(doc.reference);
    }
    for (final favorite in favorites) {
      batch.set(
        ref.collection('favorites').doc(favorite.id),
        PlaceDto.fromEntity(favorite).toJson(),
      );
    }
    await batch.commit();
  }

  Future<void> dispose() async {
    await _foreground?.cancel();
    await _opened?.cancel();
    await _tokens?.cancel();
  }
}
