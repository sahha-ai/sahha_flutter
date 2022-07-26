import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SahhaEnvironment { development, production }

enum SahhaSensor { sleep, pedometer, device }

enum SahhaSensorStatus { pending, unavailable, disabled, enabled }

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

  static Future<SahhaSensorStatus> getSensorStatus(SahhaSensor sensor) async {
    try {
      int statusInt = await _channel
          .invokeMethod('getSensorStatus', {'sensor': describeEnum(sensor)});
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaSensorStatus> enableSensor(SahhaSensor sensor) async {
    try {
      int statusInt = await _channel
          .invokeMethod('enableSensor', {'sensor': describeEnum(sensor)});
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
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

  static Future<String> analyze(
      {DateTime? startDate, DateTime? endDate, bool? includeSourceData}) async {
    try {
      int? startDateInt;
      int? endDateInt;
      if (startDate != null && endDate != null) {
        startDateInt = startDate.millisecondsSinceEpoch;
        endDateInt = endDate.millisecondsSinceEpoch;
      }
      String value = await _channel.invokeMethod('analyze', {
        'startDate': startDateInt,
        'endDate': endDateInt,
        'includeSourceData': includeSourceData
      });
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }
}
