import 'package:sahha_flutter/sahha_flutter.dart';

/// Buckets the long [SahhaSensor] enum into readable groups for pickers and
/// the diagnostics screen.
String sensorGroupOf(SahhaSensor sensor) {
  if (sensor == SahhaSensor.gender || sensor == SahhaSensor.date_of_birth) {
    return 'Demographic';
  }
  if (sensor.name.endsWith('_intake')) {
    return 'Nutrition';
  }
  if (sensor.index >= SahhaSensor.abdominal_cramps.index) {
    return 'Symptoms';
  }
  if (sensor.index >= SahhaSensor.menstrual_flow.index) {
    return 'Reproductive';
  }
  if (sensor == SahhaSensor.sleep) {
    return 'Sleep';
  }
  if (sensor == SahhaSensor.device_lock) {
    return 'Device';
  }
  if (_activitySensors.contains(sensor)) {
    return 'Activity & Mobility';
  }
  if (_bodySensors.contains(sensor)) {
    return 'Body';
  }
  return 'Vitals';
}

/// Sensors in [SahhaSensor.values] order, sorted so that each group is
/// contiguous (group order follows first appearance in the enum).
List<SahhaSensor> sensorsGroupedInEnumOrder() {
  final byGroup = <String, List<SahhaSensor>>{};
  for (final sensor in SahhaSensor.values) {
    byGroup.putIfAbsent(sensorGroupOf(sensor), () => []).add(sensor);
  }
  return [for (final group in byGroup.values) ...group];
}

const _activitySensors = <SahhaSensor>{
  SahhaSensor.steps,
  SahhaSensor.floors_climbed,
  SahhaSensor.active_energy_burned,
  SahhaSensor.basal_energy_burned,
  SahhaSensor.total_energy_burned,
  SahhaSensor.basal_metabolic_rate,
  SahhaSensor.time_in_daylight,
  SahhaSensor.stand_time,
  SahhaSensor.move_time,
  SahhaSensor.exercise_time,
  SahhaSensor.activity_summary,
  SahhaSensor.exercise,
  SahhaSensor.running_speed,
  SahhaSensor.running_power,
  SahhaSensor.running_ground_contact_time,
  SahhaSensor.running_stride_length,
  SahhaSensor.running_vertical_oscillation,
  SahhaSensor.six_minute_walk_test_distance,
  SahhaSensor.stair_ascent_speed,
  SahhaSensor.stair_descent_speed,
  SahhaSensor.walking_speed,
  SahhaSensor.walking_steadiness,
  SahhaSensor.walking_asymmetry_percentage,
  SahhaSensor.walking_double_support_percentage,
  SahhaSensor.walking_step_length,
};

const _bodySensors = <SahhaSensor>{
  SahhaSensor.height,
  SahhaSensor.weight,
  SahhaSensor.lean_body_mass,
  SahhaSensor.body_mass_index,
  SahhaSensor.body_fat,
  SahhaSensor.body_water_mass,
  SahhaSensor.bone_mass,
  SahhaSensor.waist_circumference,
  SahhaSensor.body_temperature,
  SahhaSensor.basal_body_temperature,
  SahhaSensor.sleeping_wrist_temperature,
};
