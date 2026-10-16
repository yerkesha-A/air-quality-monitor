import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Explicit controlled Crashlytics event on Android', (
    tester,
  ) async {
    await Firebase.initializeApp();
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    await crashlytics.setCustomKey(
      'verification',
      'android-completion-20261016',
    );
    await crashlytics.recordError(
      StateError('AQM controlled verification 20261016'),
      StackTrace.current,
      reason: 'Intentional non-fatal university verification',
      fatal: false,
    );
    await crashlytics.sendUnsentReports();
    // Console receipt must be confirmed separately. Normal debug app disables collection.
  }, skip: !const bool.fromEnvironment('VERIFY_CRASHLYTICS'));
}
