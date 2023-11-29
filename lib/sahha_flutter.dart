import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SahhaEnvironment { sandbox, production }

enum SahhaSensor { sleep, activity, device, heart, blood, oxygen, energy, body }

enum SahhaSensorStatus { pending, unavailable, disabled, enabled }

class SahhaNotificationSettings {
  final String? icon, title, shortDescription;
  const SahhaNotificationSettings(
      {this.icon, this.title, this.shortDescription});
}

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');
  static const List<SahhaSensor> sensorList = [
    SahhaSensor.sleep,
    SahhaSensor.activity,
    SahhaSensor.device,
    SahhaSensor.heart,
    SahhaSensor.blood,
    SahhaSensor.oxygen,
    SahhaSensor.energy,
    SahhaSensor.body
  ];

  static Future<bool> configure(
      {required SahhaEnvironment environment,
      List<SahhaSensor> sensors = sensorList,
      Map<String, String> notificationSettings =
          const <String, String>{}}) async {
    // Convert to strings
    List<String> sensorStrings = sensors.map(describeEnum).toList();
    try {
      bool success = await _channel.invokeMethod('configure', {
        'environment': describeEnum(environment),
        'notificationSettings': notificationSettings,
        'sensors': sensorStrings
      });
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> isAuthenticated() async {
    try {
      bool success = await _channel.invokeMethod('isAuthenticated');
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> authenticate(
      {required String appId,
      required String appSecret,
      required String externalId}) async {
    try {
      bool success = await _channel.invokeMethod('authenticate',
          {'appId': appId, 'appSecret': appSecret, 'externalId': externalId});
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> authenticateToken(
      {required String profileToken, required String refreshToken}) async {
    try {
      bool success = await _channel.invokeMethod('authenticateToken',
          {'profileToken': profileToken, 'refreshToken': refreshToken});
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> deauthenticate() async {
    try {
      bool success = await _channel.invokeMethod('deauthenticate');
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

  static Future<SahhaSensorStatus> getSensorStatus() async {
    try {
      int statusInt = await _channel.invokeMethod('getSensorStatus');
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaSensorStatus> enableSensors() async {
    try {
      int statusInt = await _channel.invokeMethod('enableSensors');
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }

  static void openAppSettings() {
    _channel.invokeMethod('openAppSettings');
  }

  static Future<bool> postSensorData() async {
    try {
      bool success = await _channel.invokeMethod('postSensorData');
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

  static Future<String> analyzeDateRange(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('analyzeDateRange',
          {'startDate': startDateInt, 'endDate': endDateInt});
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    }
  }
}
