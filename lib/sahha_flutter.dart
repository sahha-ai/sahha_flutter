import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SahhaEnvironment { development, production }
enum SahhaSensor { sleep, pedometer, device }
enum SahhaActivity { motion, health }
enum SahhaActivityStatus { pending, unavailable, disabled, enabled }

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');
  static const List<SahhaSensor> sensorList = [
    SahhaSensor.sleep,
    SahhaSensor.pedometer,
    SahhaSensor.device
  ];

  static Future<bool> configure(
      {required SahhaEnvironment environment,
      List<SahhaSensor> sensors = sensorList,
      bool postActivityManually = false}) async {
    // Convert to strings
    List<String> sensorStrings = sensors.map(describeEnum).toList();
    try {
      bool success = await _channel.invokeMethod('configure',
          [describeEnum(environment), sensorStrings, postActivityManually]);
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> authenticate(String token, String refreshToken) async {
    try {
      bool success =
          await _channel.invokeMethod('authenticate', [token, refreshToken]);
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> postDemographic({int? age, String? gender}) async {
    try {
      bool success =
          await _channel.invokeMethod('postDemographic', [age, gender]);
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaActivityStatus> activityStatus(
      SahhaActivity activity) async {
    try {
      int statusInt = await _channel
          .invokeMethod('activityStatus', [describeEnum(activity)]);
      SahhaActivityStatus status = SahhaActivityStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaActivityStatus> activate(SahhaActivity activity) async {
    try {
      int statusInt =
          await _channel.invokeMethod('activate', [describeEnum(activity)]);
      SahhaActivityStatus status = SahhaActivityStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaActivityStatus> promptUserToActivate(
      SahhaActivity activity) async {
    try {
      int statusInt = await _channel
          .invokeMethod('promptUserToActivate', [describeEnum(activity)]);
      SahhaActivityStatus status = SahhaActivityStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static void openAppSettings() {
    _channel.invokeMethod('openAppSettings');
  }

  static Future<bool> postActivity(SahhaActivity activity) async {
    try {
      bool success =
          await _channel.invokeMethod('postActivity', [describeEnum(activity)]);
      return success;
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
}
