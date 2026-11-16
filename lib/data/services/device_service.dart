import 'package:flutter/services.dart';

class DeviceService {
  const DeviceService({
    this.channel = const MethodChannel('air_quality_monitor/device'),
  });
  final MethodChannel channel;

  Future<Map<String, dynamic>> info() async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      if (result == null) return _unavailable;
      return Map<String, dynamic>.from(result);
    } on MissingPluginException {
      return _unavailable;
    } on PlatformException {
      return _unavailable;
    }
  }

  static const _unavailable = <String, dynamic>{
    'available': false,
    'model': null,
    'sdk': null,
    'battery': null,
    'mapsConfigured': false,
    'firebaseConfigured': false,
    'googleClientId': '',
  };
}
