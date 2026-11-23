import 'dart:async';

import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/services/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Store extends Mock implements LocalStore {}

void main() {
  test(
    'Notification tap persists before navigation reads the history',
    () async {
      final store = _Store();
      final committed = Completer<void>();
      when(
        () => store.recordAlert(
          id: 'server-message',
          title: 'Air warning',
          body: 'Updated AQI',
          source: 'push',
        ),
      ).thenAnswer((_) => committed.future);
      final service = FirebaseService(configured: false);
      String? route;
      service.onOpen = (value) => route = value;
      final opening = service.handleOpenedMessage(
        const RemoteMessage(
          messageId: 'server-message',
          notification: RemoteNotification(
            title: 'Air warning',
            body: 'Updated AQI',
          ),
        ),
        store,
      );
      await Future<void>.delayed(Duration.zero);
      expect(route, isNull);
      committed.complete();
      await opening;
      expect(route, '/alerts');
      verify(
        () => store.recordAlert(
          id: 'server-message',
          title: 'Air warning',
          body: 'Updated AQI',
          source: 'push',
        ),
      ).called(1);
    },
  );

  test(
    'Data-only payload keeps its server id and safe display defaults',
    () async {
      final store = _Store();
      when(
        () => store.recordAlert(
          id: 'data-only-id',
          title: 'Качество воздуха',
          body: '',
          source: 'push',
        ),
      ).thenAnswer((_) async {});
      await recordPushMessage(
        const RemoteMessage(messageId: 'data-only-id'),
        store,
      );
      verify(
        () => store.recordAlert(
          id: 'data-only-id',
          title: 'Качество воздуха',
          body: '',
          source: 'push',
        ),
      ).called(1);
    },
  );
}
