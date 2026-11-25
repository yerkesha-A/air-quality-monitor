import 'package:air_quality_monitor/data/services/notification_service.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

class _Notifications extends NotificationService {
  _Notifications(SharedPreferences preferences)
    : super(MockLocalStore(), preferences);
  int sent = 0;
  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    String source = 'local',
  }) async {
    sent++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Alert threshold matches the displayed integer and stays deduplicated',
    () async {
      SharedPreferences.setMockInitialValues({});
      final notifications = _Notifications(
        await SharedPreferences.getInstance(),
      );
      final now = DateTime.now().toUtc();
      final report = AirReport(
        place: fixturePlace,
        current: AirPoint(time: now, values: {'us_aqi': 99.6}),
        forecast: [],
        fetchedAt: now,
        utcOffsetSeconds: 0,
      );
      await notifications.check(report, enabled: true, threshold: 100);
      expect(notifications.sent, 1);
      await notifications.check(report, enabled: true, threshold: 100);
      expect(notifications.sent, 1);
    },
  );
}
