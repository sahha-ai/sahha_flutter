import 'dart:async';

import 'package:flutter/services.dart';

enum SahhaEnvironment { sandbox, production }

enum SahhaSensor {
  gender,
  date_of_birth,
  sleep,
  step_count,
  floor_count,
  heart_rate,
  resting_heart_rate,
  walking_heart_rate_average,
  heart_rate_variability_sdnn,
  heart_rate_variability_rmssd,
  blood_pressure_systolic,
  blood_pressure_diastolic,
  blood_glucose,
  vo2_max,
  oxygen_saturation,
  respiratory_rate,
  active_energy_burned,
  basal_energy_burned,
  total_energy_burned,
  basal_metabolic_rate,
  time_in_daylight,
  body_temperature,
  basal_body_temperature,
  sleeping_wrist_temperature,
  height,
  weight,
  lean_body_mass,
  body_mass_index,
  body_fat,
  body_water_mass,
  bone_mass,
  waist_circumference,
  stand_time,
  move_time,
  exercise_time,
  activity_summary,
  device_lock,
  exercise
}

enum SahhaScoreType {
  wellbeing,
  activity,
  sleep,
  readiness,
  mental_wellbeing,
}

enum SahhaSensorStatus { pending, unavailable, disabled, enabled }

class SahhaNotificationSettings {
  final String? icon, title, shortDescription;

  const SahhaNotificationSettings(
      {this.icon, this.title, this.shortDescription});
}

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');
  static const List<SahhaSensor> sensorList = [
    SahhaSensor.gender,
    SahhaSensor.date_of_birth,
    SahhaSensor.sleep,
    SahhaSensor.step_count,
    SahhaSensor.floor_count,
    SahhaSensor.heart_rate,
    SahhaSensor.resting_heart_rate,
    SahhaSensor.walking_heart_rate_average,
    SahhaSensor.heart_rate_variability_sdnn,
    SahhaSensor.heart_rate_variability_rmssd,
    SahhaSensor.blood_pressure_systolic,
    SahhaSensor.blood_pressure_diastolic,
    SahhaSensor.blood_glucose,
    SahhaSensor.vo2_max,
    SahhaSensor.oxygen_saturation,
    SahhaSensor.respiratory_rate,
    SahhaSensor.active_energy_burned,
    SahhaSensor.basal_energy_burned,
    SahhaSensor.total_energy_burned,
    SahhaSensor.basal_metabolic_rate,
    SahhaSensor.time_in_daylight,
    SahhaSensor.body_temperature,
    SahhaSensor.basal_body_temperature,
    SahhaSensor.sleeping_wrist_temperature,
    SahhaSensor.height,
    SahhaSensor.weight,
    SahhaSensor.lean_body_mass,
    SahhaSensor.body_mass_index,
    SahhaSensor.body_fat,
    SahhaSensor.body_water_mass,
    SahhaSensor.bone_mass,
    SahhaSensor.waist_circumference,
    SahhaSensor.stand_time,
    SahhaSensor.move_time,
    SahhaSensor.exercise_time,
    SahhaSensor.activity_summary,
    SahhaSensor.device_lock,
    SahhaSensor.exercise
  ];

  static Future<bool> configure(
      {required SahhaEnvironment environment,
      Map<String, String> notificationSettings =
          const <String, String>{}}) async {
    try {
      bool success = await _channel.invokeMethod('configure', {
        'environment': environment.name,
        'notificationSettings': notificationSettings
      });
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> isAuthenticated() async {
    try {
      bool success = await _channel.invokeMethod('isAuthenticated');
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
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
    } catch (error) {
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
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<bool> deauthenticate() async {
    try {
      bool success = await _channel.invokeMethod('deauthenticate');
      return success;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String?> getProfileToken() async {
    try {
      String? value = await _channel.invokeMethod('getProfileToken');
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String?> getDemographic() async {
    try {
      String? value = await _channel.invokeMethod('getDemographic');
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
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
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaSensorStatus> getSensorStatus(
      List<SahhaSensor> sensors) async {
    try {
      List<String> sensorStrings =
          sensors.map((sensor) => sensor.name).toList();
      int statusInt = await _channel
          .invokeMethod('getSensorStatus', {'sensors': sensorStrings});
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<SahhaSensorStatus> enableSensors(
      List<SahhaSensor> sensors) async {
    try {
      List<String> sensorStrings =
          sensors.map((sensor) => sensor.name).toList();
      int statusInt = await _channel
          .invokeMethod('enableSensors', {'sensors': sensorStrings});
      SahhaSensorStatus status = SahhaSensorStatus.values[statusInt];
      return status;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static void openAppSettings() {
    _channel.invokeMethod('openAppSettings');
  }

  static Future<String> getScores({required List<SahhaScoreType> types}) async {
    try {
      List<String> scoreTypeStrings = types.map((type) => type.name).toList();
      String value =
          await _channel.invokeMethod('getScores', {'types': scoreTypeStrings});
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> getScoresDateRange(
      {required List<SahhaScoreType> types,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      List<String> scoreTypeStrings = types.map((type) => type.name).toList();
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('getScoresDateRange',
          {'types': scoreTypeStrings, 'startDate': startDateInt, 'endDate': endDateInt});
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }
}
