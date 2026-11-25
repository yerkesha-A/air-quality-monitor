import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store extends Mock implements LocalStore {}

void main() {
  testWidgets(
    'iOS notifications initialize without a prompt and ask only on request',
    (tester) async {
      IOSFlutterLocalNotificationsPlugin.registerWith();
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'getNotificationAppLaunchDetails'
            ? {'notificationLaunchedApp': false}
            : true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({});
      final store = _Store();
      when(
        () => store.recordAlert(
          id: 'test',
          title: 'AQI',
          body: 'Test',
          source: 'local',
        ),
      ).thenAnswer((_) async {});
      final service = NotificationService(
        store,
        await SharedPreferences.getInstance(),
      );
      await service.initialize();
      final init =
          calls.singleWhere((c) => c.method == 'initialize').arguments as Map;
      expect(init['requestAlertPermission'], isFalse);
      expect(init['requestSoundPermission'], isFalse);
      expect(init['requestBadgePermission'], isFalse);
      expect(calls.where((c) => c.method == 'requestPermissions'), isEmpty);
      expect(await service.requestPermission(), isTrue);
      expect(
        calls.singleWhere((c) => c.method == 'requestPermissions').arguments,
        containsPair('alert', true),
      );
      await service.show(id: 'test', title: 'AQI', body: 'Test');
      expect(calls.where((c) => c.method == 'show'), hasLength(1));
      verify(
        () => store.recordAlert(
          id: 'test',
          title: 'AQI',
          body: 'Test',
          source: 'local',
        ),
      ).called(1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
