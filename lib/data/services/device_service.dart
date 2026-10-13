import 'package:flutter/services.dart';

class DeviceService {
  static const _channel = MethodChannel('air_quality_monitor/device');
  Future<Map<String, dynamic>> info() async => Map<String, dynamic>.from(
    await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo') ?? {},
  );
}
