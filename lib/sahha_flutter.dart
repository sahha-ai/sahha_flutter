import 'dart:async';

import 'package:flutter/services.dart';

enum ActivityStatus { pending, unavailable, disabled, enabled }

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');

  static void configure() {}

  static Future<String> authenticate(
      String customerId, String profileId) async {
    String token = '';
    return token;
  }

  static Future<String> get analysis async {
    var data = "";
    return data;
  }

  static Future<ActivityStatus> get activityStatus async {
    ActivityStatus value = ActivityStatus.enabled;
    return value;
  }

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
