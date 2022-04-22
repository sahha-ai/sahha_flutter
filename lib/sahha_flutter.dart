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
      bool postSensorDataManually = false}) async {
    // Convert to strings
    List<String> sensorStrings = sensors.map(describeEnum).toList();
    try {
      bool success = await _channel.invokeMethod('configure', {
        'environment': describeEnum(environment),
        'sensors': sensorStrings,
        'postSensorDataManually': postSensorDataManually
      });
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> authenticate(
      String profileToken, String refreshToken) async {
    try {
      bool success = await _channel.invokeMethod('authenticate',
          {'profileToken': profileToken, 'refreshToken': refreshToken});
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> getDemographic() async {
    try {
      String value = await _channel.invokeMethod('getDemographic');
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> postDemographic(Map demographic) async {
    try {
      bool success =
          await _channel.invokeMethod('postDemographic', demographic);
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaActivityStatus> activityStatus(
      SahhaActivity activity) async {
    try {
      int statusInt = await _channel
          .invokeMethod('activityStatus', {'activity': describeEnum(activity)});
      SahhaActivityStatus status = SahhaActivityStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaActivityStatus> activate(SahhaActivity activity) async {
    try {
      int statusInt = await _channel
          .invokeMethod('activate', {'activity': describeEnum(activity)});
      SahhaActivityStatus status = SahhaActivityStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static void openAppSettings() {
    _channel.invokeMethod('openAppSettings');
  }

  static Future<bool> postSensorData(
      {List<SahhaSensor> sensors = sensorList}) async {
    try {
      // Convert to strings
      List<String> sensorStrings = sensors.map(describeEnum).toList();
      bool success = await _channel
          .invokeMethod('postSensorData', {'sensors': sensorStrings});
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
