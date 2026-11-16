import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality_monitor/data/services/device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('aqm-test/device');
  const service = DeviceService(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test(
    'Dart invokes the own channel method and preserves real Android payload',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getDeviceInfo');
        return {
          'available': true,
          'battery': 77,
          'sdk': 37,
          'model': 'Android test device',
          'firebaseConfigured': true,
          'mapsConfigured': false,
          'googleClientId': 'test-client',
        };
      });
      final info = await service.info();
      expect(info['battery'], 77);
      expect(info['sdk'], 37);
      expect(info['firebaseConfigured'], isTrue);
    },
  );
  for (final failure in [
    MissingPluginException(),
    PlatformException(code: 'DEVICE_INFO_UNAVAILABLE'),
  ]) {
    test(
      'Unavailable method returns explicit unavailable state: ${failure.runtimeType}',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async => throw failure);
        final info = await service.info();
        expect(info['available'], isFalse);
        expect(info['battery'], isNull);
        expect(info['firebaseConfigured'], isFalse);
      },
    );
  }
  test(
    'Null native response is unavailable, not invented device data',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      final info = await service.info();
      expect(info['available'], isFalse);
      expect(info['model'], isNull);
    },
  );
}
