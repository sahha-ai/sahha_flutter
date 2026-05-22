import 'dart:async';

import 'package:flutter/services.dart';

enum SahhaEnvironment {  sandbox, production}

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
  exercise,
  running_speed,
  running_power,
  running_ground_contact_time,
  running_stride_length,
  running_vertical_oscillation,
  six_minute_walk_test_distance,
  stair_ascent_speed,
  stair_descent_speed,
  walking_speed,
  walking_steadiness,
  walking_asymmetry_percentage,
  walking_double_support_percentage,
  walking_step_length,

  // Nutrition
  energy_intake,
  protein_intake,
  fat_intake,
  fat_saturated_intake,
  fat_monounsaturated_intake,
  fat_polyunsaturated_intake,
  cholesterol_intake,
  carbohydrate_intake,
  sugar_intake,
  fiber_intake,
  vitamin_a_intake,
  vitamin_c_intake,
  vitamin_d_intake,
  vitamin_e_intake,
  vitamin_k_intake,
  vitamin_b6_intake,
  vitamin_b12_intake,
  thiamin_intake,
  riboflavin_intake,
  niacin_intake,
  pantothenic_acid_intake,
  folate_intake,
  biotin_intake,
  calcium_intake,
  iron_intake,
  magnesium_intake,
  phosphorus_intake,
  potassium_intake,
  sodium_intake,
  zinc_intake,
  chloride_intake,
  copper_intake,
  manganese_intake,
  chromium_intake,
  molybdenum_intake,
  selenium_intake,
  iodine_intake,
  caffeine_intake,
  water_intake,

  // Reproductive
  menstrual_flow,
  menstrual_period,
  intermenstrual_bleeding,
  cervical_mucus,
  ovulation_test,
  sexual_activity,
  pregnancy,
  pregnancy_test,
  progesterone_test,
  lactation,
  contraceptive,
  infrequent_menstrual_cycles,
  irregular_menstrual_cycles,
  persistent_intermenstrual_bleeding,
  prolonged_menstrual_periods,

  // Symptoms
  abdominal_cramps,
  acne,
  appetite_changes,
  bladder_incontinence,
  bloating,
  breast_pain,
  chest_tightness_or_pain,
  chills,
  constipation,
  coughing,
  diarrhea,
  dizziness,
  dry_skin,
  fainting,
  fatigue,
  fever,
  generalized_body_ache,
  hair_loss,
  headache,
  heartburn,
  hot_flashes,
  loss_of_smell,
  loss_of_taste,
  lower_back_pain,
  memory_lapse,
  mood_changes,
  nausea,
  night_sweats,
  pelvic_pain,
  rapid_pounding_or_fluttering_heartbeat,
  runny_nose,
  shortness_of_breath,
  sinus_congestion,
  skipped_heartbeat,
  sleep_changes,
  sore_throat,
  vaginal_dryness,
  vomiting,
  wheezing,
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
  vitals,
  nutrition
}

enum SahhaSensorStatus { pending, unavailable, disabled, enabled }

class SahhaNotificationSettings {
  final String? icon, title, shortDescription;

  const SahhaNotificationSettings(
      {this.icon, this.title, this.shortDescription});
}

class SahhaFlutter {
  static const MethodChannel _channel = MethodChannel('sahha_flutter');

  static Future<bool> configure({
    required SahhaEnvironment environment,
    Map<String, String> notificationSettings = const <String, String>{},
    bool enableMotionTrigger = false, 
  }) async {
    try {
      final bool success = await _channel.invokeMethod('configure', {
        'environment': environment.name,
        'notificationSettings': notificationSettings,
        'enableMotionTrigger': enableMotionTrigger,
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

static Future<SahhaSensorStatus> getSensorStatus(List<SahhaSensor> sensors) async {
  try {
    final sensorStrings = sensors.map((s) => s.name).toList();
    final raw = await _channel.invokeMethod('getSensorStatus', {'sensors': sensorStrings});
    return _statusFromNative(raw);
  } on PlatformException catch (error) {
    return Future.error(error);
  } catch (error) {
    return Future.error(error);
  }
}


static SahhaSensorStatus _statusFromNative(dynamic raw) {
  final name = raw.toString().trim().toLowerCase();
  // Unknown/future statuses (e.g. iOS "indeterminate") fall back to pending.
  return SahhaSensorStatus.values.firstWhere(
    (e) => e.name == name,
    orElse: () => SahhaSensorStatus.pending,
  );
}

static Future<SahhaSensorStatus> enableSensors(List<SahhaSensor> sensors) async {
  try {
    final sensorStrings = sensors.map((s) => s.name).toList();
    final raw = await _channel.invokeMethod('enableSensors', {'sensors': sensorStrings});
    return _statusFromNative(raw);
  } on PlatformException catch (error) {
    return Future.error(error);
  } catch (error) {
    return Future.error(error);
  }
}


  static void postSensorData() {
    _channel.invokeMethod('postSensorData');
  }

  static void openAppSettings() {
    _channel.invokeMethod('openAppSettings');
  }

  static Future<String> getScores(
      {required List<SahhaScoreType> types,
      required DateTime startDateTime,
      required DateTime endDateTime}) async {
    try {
      List<String> scoreTypeStrings = types.map((type) => type.name).toList();
      int startDateInt = startDateTime.millisecondsSinceEpoch;
      int endDateInt = endDateTime.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('getScores', {
        'types': scoreTypeStrings,
        'startDateTime': startDateInt,
        'endDateTime': endDateInt
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
      required DateTime startDateTime,
      required DateTime endDateTime}) async {
    try {
      List<String> biomarkerCategoryStrings =
          categories.map((category) => category.name).toList();
      List<String> biomarkerTypeStrings =
          types.map((type) => type.name).toList();
      int startDateInt = startDateTime.millisecondsSinceEpoch;
      int endDateInt = endDateTime.millisecondsSinceEpoch;
      String value = await _channel.invokeMethod('getBiomarkers', {
        'categories': biomarkerCategoryStrings,
        'types': biomarkerTypeStrings,
        'startDateTime': startDateInt,
        'endDateTime': endDateInt
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
      required DateTime startDateTime,
      required DateTime endDateTime}) async {
    try {
      int startDateInt = startDateTime.millisecondsSinceEpoch;
      int endDateInt = endDateTime.millisecondsSinceEpoch;
      String stats = await _channel.invokeMethod('getStats', {
        'sensor': sensor.name,
        'startDateTime': startDateInt,
        'endDateTime': endDateInt
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
      required DateTime startDateTime,
      required DateTime endDateTime}) async {
    try {
      int startDateInt = startDateTime.millisecondsSinceEpoch;
      int endDateInt = endDateTime.millisecondsSinceEpoch;
      String samples = await _channel.invokeMethod('getSamples', {
        'sensor': sensor.name,
        'startDateTime': startDateInt,
        'endDateTime': endDateInt
      });
      return samples;
    } on PlatformException catch (error) {
      return Future.error(error);
    } catch (error) {
      return Future.error(error);
    }
  }
}
