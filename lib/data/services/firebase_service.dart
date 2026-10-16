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
import 'cloud_sync.dart';

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
  bool _pushEnabled = false;
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
      if (_pushEnabled && uid != null) {
        try {
          await _saveToken(uid, token);
        } catch (_) {
          // Retry registration on the next sync; keep stream errors contained.
        }
      }
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
    if (token != null) {
      await _saveToken(account.id, token);
      _pushEnabled = true;
    }
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
    _pushEnabled = false;
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

  Future<void> restorePush(Account account, {required bool enabled}) async {
    if (!configured) return;
    if (!enabled) {
      if (_pushEnabled) await unregisterDevice();
      return;
    }
    final permission = await FirebaseMessaging.instance
        .getNotificationSettings();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && FirebaseAuth.instance.currentUser?.uid == account.id) {
      await _saveToken(account.id, token);
      _pushEnabled = true;
    }
  }

  late final CloudSync cloudSync = CloudSync(_FirestoreSyncGateway());

  Future<void> dispose() async {
    await _foreground?.cancel();
    await _opened?.cancel();
    await _tokens?.cancel();
  }
}

class _FirestoreSyncGateway implements CloudSyncGateway {
  @override
  Future<CloudSnapshot> read(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    // Do not mistake an empty SDK cache for an empty cloud account.
    final user = await ref.get(const GetOptions(source: Source.server));
    final favorites = await ref
        .collection('favorites')
        .get(const GetOptions(source: Source.server));
    return CloudSnapshot(
      settings: user.data(),
      favorites: favorites.docs
          .map((doc) => PlaceDto.fromJson(doc.data()).toEntity())
          .toList(),
    );
  }

  @override
  Future<void> write(
    String uid,
    Map<String, dynamic> settings,
    List<Place> favorites,
    Set<String> removedIds,
  ) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Account changed during cloud sync');
    }
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(uid);
    await ref.set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Never infer deletion from an empty/partial local list. Only explicit
    // user removals may delete cloud documents. Chunk for Firestore's batch limit.
    final operations = <void Function(WriteBatch)>[
      for (final id in removedIds)
        (batch) => batch.delete(ref.collection('favorites').doc(id)),
      for (final place in favorites.where((p) => !removedIds.contains(p.id)))
        (batch) => batch.set(
          ref.collection('favorites').doc(place.id),
          PlaceDto.fromEntity(place).toJson(),
        ),
    ];
    for (var start = 0; start < operations.length; start += 400) {
      final batch = db.batch();
      for (final operation in operations.skip(start).take(400)) {
        operation(batch);
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Account changed during cloud sync');
      }
      await batch.commit();
    }
  }
}
