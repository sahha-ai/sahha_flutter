import 'dart:async';

import 'package:flutter/services.dart';

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get bundleId async {
    String value;
    try {
      value = await _channel.invokeMethod('getBundleId');
    } on PlatformException catch (e) {
      value = "Failed to get bundle id: '${e.message}'.";
    }
    return value;
  }

  static Future<String> get batteryLevel async {
    String value;
    try {
      value = await _channel.invokeMethod('getBatteryLevel');
    } on PlatformException catch (e) {
      value = "Failed to get battery level: '${e.message}'.";
    }
    return value;
  }
}
