import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

enum SahhaEnvironment { sandbox, production }

enum SahhaSensor {
  gender,
  date_of_birth,
  sleep,
  steps,
  floors_climbed,
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

enum SahhaBiomarkerType {
  steps,
  floors_climbed,
  active_hours,
  active_duration,
  activity_low_intensity_duration,
  activity_mid_intensity_duration,
  activity_high_intensity_duration,
  activity_sedentary_duration,
  active_energy_burned,
  total_energy_burned,
  height,
  weight,
  body_mass_index,
  body_fat,
  fat_mass,
  lean_mass,
  waist_circumference,
  resting_energy_burned,
  age,
  biological_sex,
  date_of_birth,
  menstrual_cycle_length,
  menstrual_cycle_start_date,
  menstrual_cycle_end_date,
  menstrual_phase,
  menstrual_phase_start_date,
  menstrual_phase_end_date,
  menstrual_phase_length,
  sleep_start_time,
  sleep_end_time,
  sleep_duration,
  sleep_debt,
  sleep_interruptions,
  sleep_in_bed_duration,
  sleep_awake_duration,
  sleep_light_duration,
  sleep_rem_duration,
  sleep_deep_duration,
  sleep_regularity,
  sleep_latency,
  sleep_efficiency,
  heart_rate_resting,
  heart_rate_sleep,
  heart_rate_variability_sdnn,
  heart_rate_variability_rmssd,
  respiratory_rate,
  respiratory_rate_sleep,
  oxygen_saturation,
  oxygen_saturation_sleep,
  vo2_max,
  blood_glucose,
  blood_pressure_systolic,
  blood_pressure_diastolic,
  body_temperature_basal,
  skin_temperature_sleep,
}

enum SahhaBiomarkerCategory {
  activity,
  body,
  characteristic,
  reproductive,
  sleep,
  vitals
}

enum SahhaSensorStatus { pending, unavailable, disabled, enabled }

class SahhaNotificationSettings {
  final String? icon, title, shortDescription;

  const SahhaNotificationSettings(
      {this.icon, this.title, this.shortDescription});
}

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');

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

  static Future<String> getScores(
      {required List<SahhaScoreType> types,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      List<String> scoreTypeStrings = types.map((type) => type.name).toList();
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('getScores', {
        'types': scoreTypeStrings,
        'startDate': startDateInt,
        'endDate': endDateInt
      });
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> getBiomarkers(
      {required List<SahhaBiomarkerCategory> categories,
      required List<SahhaBiomarkerType> types,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      List<String> biomarkerCategoryStrings =
          categories.map((category) => category.name).toList();
      List<String> biomarkerTypeStrings =
          types.map((type) => type.name).toList();
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('getBiomarkers', {
        'categories': biomarkerCategoryStrings,
        'types': biomarkerTypeStrings,
        'startDate': startDateInt,
        'endDate': endDateInt
      });
      return value;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> getStats(
      {required SahhaSensor sensor,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String stats = await _channel.invokeMethod('getStats', {
        'sensor': sensor.name,
        'startDate': startDateInt,
        'endDate': endDateInt
      });
      return stats;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }

  static Future<String> getSamples(
      {required SahhaSensor sensor,
      required DateTime startDate,
      required DateTime endDate}) async {
    try {
      int startDateInt = startDate.millisecondsSinceEpoch;
      int endDateInt = endDate.millisecondsSinceEpoch;
      String stats = await _channel.invokeMethod('getSamples', {
        'sensor': sensor.name,
        'startDate': startDateInt,
        'endDate': endDateInt
      });
      return stats;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }
}
