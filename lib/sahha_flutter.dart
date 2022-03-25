import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ActivityStatus { pending, unavailable, disabled, enabled }

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');

  static void configure() {}

  static Future<String> authenticate(
      String customerId, String profileId) async {
    try {
      String token =
          await _channel.invokeMethod('authenticate', [customerId, profileId]);
      return token;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> analyze() async {
    try {
      String value = await _channel.invokeMethod('analyze');
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<ActivityStatus> get activityStatus async {
    ActivityStatus value = ActivityStatus.enabled;
    return value;
  }

  static Future<String> get platformVersion async {
    String value;
    try {
      value = await _channel.invokeMethod('getPlatformVersion');
    } on PlatformException catch (e) {
      value = "Failed to get platformVersion: '${e.message}'.";
    }
    return value;
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
