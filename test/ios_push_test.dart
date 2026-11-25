import 'package:air_quality_monitor/data/services/firebase_service.dart';
import 'package:air_quality_monitor/domain/repositories/auth_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Messaging extends Mock implements FirebaseMessaging {}

void main() {
  test(
    'iOS push waits for APNs instead of requesting FCM token prematurely',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final messaging = _Messaging();
      when(() => messaging.requestPermission()).thenAnswer(
        (_) async => const NotificationSettings(
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.notSupported,
          authorizationStatus: AuthorizationStatus.authorized,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );
      when(() => messaging.getAPNSToken()).thenAnswer((_) async => null);
      final service = FirebaseService(configured: true, messaging: messaging);
      expect(
        await service.enablePush(
          const Account(id: 'test', email: 'user@example.test'),
        ),
        isFalse,
      );
      verify(() => messaging.getAPNSToken()).called(1);
      verifyNever(() => messaging.getToken());
    },
  );
}
