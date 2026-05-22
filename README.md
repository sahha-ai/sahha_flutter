# Sahha SDK for Flutter Apps

The Sahha SDK provides a convenient way for Flutter apps to connect to the Sahha API.

Sahha lets your project seamlessly collect health and lifestyle data from smartphones and wearables via Apple Health, Google Health Connect, and a variety of other sources.

For more information on Sahha please visit https://sahha.ai.

---

## Docs

The Sahha Docs provide detailed instructions for installation and usage of the Sahha SDK.

[Sahha Docs](https://developer.sahha.ai/docs)

---

## Example

The Sahha Demo App provides a convenient way to try the features of the Sahha SDK.

[Sahha Demo App](https://github.com/sahha-ai/sahha_flutter/tree/master/example)

---

## Health Data Source Integrations

Sahha supports integration with the following health data sources:

- [Apple Health Kit](https://sahha.notion.site/Apple-Health-HealthKit-13cb2f553bbf80c0b117cb662e04c257?pvs=25)
- [Google Fit](https://sahha.notion.site/Google-Fit-131b2f553bbf804a8ee6fef7bc1f4edb?pvs=25)
- [Google Health Connect](https://sahha.notion.site/Health-Connect-Android-13cb2f553bbf806d9d64e79fe9d07d9e?pvs=25)
- [Samsung Health](https://sahha.notion.site/Samsung-Health-d3f76840fad142469f5e724a54c24ead?pvs=25)
- [Fitbit](https://sahha.notion.site/Fitbit-12db2f553bbf809fa93ff01f9acd7330?pvs=25)
- [Garmin Connect](https://sahha.notion.site/Garmin-12db2f553bbf80afb916d04a62e857e6?pvs=25)
- [Polar Flow](https://sahha.notion.site/Polar-12db2f553bbf80c3968eeeab55b484a2?pvs=25)
- [Withings Health Mate](https://sahha.notion.site/Withings-12db2f553bbf80a38d31f80ab083613f?pvs=25)
- [Oura Ring](https://sahha.notion.site/Oura-12db2f553bbf80cf96f2dfd8343b4f06?pvs=25)
- [Whoop](https://sahha.notion.site/WHOOP-12db2f553bbf807192a5c69071e888f4?pvs=25)
- [Strava](https://sahha.notion.site/Strava-12db2f553bbf80c48312c2bf6aa5ac65?pvs=25)
- [Sleep as Android](https://sahha.notion.site/Sleep-as-Android-Smart-alarm-131b2f553bbf802eb7e4dca6baab1049?pvs=25)

& many more! Please visit our [integrations](https://sahha.notion.site/data-integrations?v=17eb2f553bbf80e0b0b3000c0983ab01) page for more information.

---

## Install

In the `pubspec.yaml` file, add the Sahha sdk to dependencies.
```yaml
dependencies:
  # Sahha
  sahha_flutter: ^1.1.4
```

### Android

On Android, sensor data is collected via Google Health Connect. In the `AndroidManifest.xml` file, which can be found in `android` > `app` > `src` > `main`, declare the Health Connect data types your project needs.

> **Important:** `enableSensors()` and `getSensorStatus()` will only ever prompt for permissions you have declared here. Any sensor you pass that does not have a matching `<uses-permission>` entry is silently ignored on Android — so if a permission isn't appearing in the Health Connect prompt, it's almost always missing from the manifest.

The full set of supported Health Connect read permissions is shown below. Only include the ones your project actually needs.

```xml
<!-- Sleep -->
<uses-permission android:name="android.permission.health.READ_SLEEP" />

<!-- Activity -->
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_FLOORS_CLIMBED" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />

<!-- Heart -->
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE_VARIABILITY" />

<!-- Energy -->
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_BASAL_METABOLIC_RATE" />

<!-- Oxygen -->
<uses-permission android:name="android.permission.health.READ_VO2_MAX" />
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION" />
<uses-permission android:name="android.permission.health.READ_RESPIRATORY_RATE" />

<!-- Blood -->
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE" />
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE" />

<!-- Body -->
<uses-permission android:name="android.permission.health.READ_HEIGHT" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_LEAN_BODY_MASS" />
<uses-permission android:name="android.permission.health.READ_BODY_FAT" />
<uses-permission android:name="android.permission.health.READ_BODY_WATER_MASS" />
<uses-permission android:name="android.permission.health.READ_BONE_MASS" />

<!-- Temperature -->
<uses-permission android:name="android.permission.health.READ_BODY_TEMPERATURE" />
<uses-permission android:name="android.permission.health.READ_BASAL_BODY_TEMPERATURE" />

<!-- Nutrition (all *_intake sensors map to READ_NUTRITION; water_intake maps to READ_HYDRATION) -->
<uses-permission android:name="android.permission.health.READ_NUTRITION" />
<uses-permission android:name="android.permission.health.READ_HYDRATION" />

<!-- Reproductive -->
<uses-permission android:name="android.permission.health.READ_MENSTRUATION" />
<uses-permission android:name="android.permission.health.READ_INTERMENSTRUAL_BLEEDING" />
<uses-permission android:name="android.permission.health.READ_CERVICAL_MUCUS" />
<uses-permission android:name="android.permission.health.READ_OVULATION_TEST" />
<uses-permission android:name="android.permission.health.READ_SEXUAL_ACTIVITY" />
```

Declaring these permissions also lets you retrieve Health Connect data shared by other health apps such as WHOOP, Garmin, Samsung Health etc.

> **Note:** not every `SahhaSensor` has a Health Connect equivalent. The symptom sensors, the demographic sensors (`gender`, `date_of_birth`), `activity_summary`, `device_lock`, and the iOS-only metrics (e.g. `heart_rate_variability_sdnn`, `body_mass_index`, `waist_circumference`, the walking/running gait sensors, pregnancy/contraceptive, etc.) have no Health Connect data type. They are safely ignored on Android and do not need a manifest entry. Several sensors also share one permission — for example all 39 nutrition sensors map to just `READ_NUTRITION` and `READ_HYDRATION`.

To declare other sensor permissions, please refer to [this](https://docs.sahha.ai/docs/data-flow/sdk/setup#step-2-review-sensor-permissions) page.

Only include the sensor permissions required by your project, what is declared here will be reviewed by the Play Store.

You must be able to justify reasons behind requiring the sensor permissions, [these](https://docs.sahha.ai/docs/data-flow/sdk/app-store-submission/google-play-store#data-type-justifications) justifications may be used to clearly articulate the reasoning behind your required sensor permissions.

### Apple iOS

#### Enable HealthKit

- Open your project in Xcode and select your `App Target` in the Project panel.
- Navigate to the `Signing & Capabilities` tab.
- Click the `+` button (or choose `Editor > Add Capability`) to open the Capabilities library.
- Locate and select `HealthKit`; double-click it to add it to your project.

#### Background Delivery
- Select your project in the Project navigator and choose your app’s target.
- In the `Signing & Capabilities` tab, find the HealthKit capability.
- Enable the nested `Background Delivery` option to allow passive health data collection.

#### Add Usage Descriptions
- Select your `App Target` and navigate to the `Info` tab.
- Click the `+` button to add a new key and choose `Privacy - Health Share Usage Description`.
- Provide a clear description, such as: "*This app needs your health info to deliver mood predictions*."

For more detailed instructions, refer to our [setup guide](https://docs.sahha.ai/docs/data-flow/sdk/setup#minimum-requirements).

---

## API

<docgen-index>

* [`configure(...)`](#configure)
* [`isAuthenticated`](#isauthenticated)
* [`authenticate()`](#authenticate)
* [`authenticateToken()`](#authenticatetoken)
* [`deauthenticate()`](#deauthenticate)
* [`getProfileToken()`](#getprofiletoken)
* [`getDemographic()`](#getdemographic)
* [`postDemographic(...)`](#postdemographic)
* [`getSensorStatus(...)`](#getsensorstatus)
* [`enableSensors(...)`](#enablesensors)
* [`getScores(...)`](#getscores)
* [`getBiomarkers(...)`](#getbiomarkers)
* [`getStats(...)`](#getstats)
* [`getSamples(...)`](#getsamples)
* [`openAppSettings()`](#openappsettings)
* [Enums](#enums)

</docgen-index>

<docgen-api>

### configure(...)

```dart
  static Future<bool> configure(
      {required SahhaEnvironment environment,
      Map<String, String> notificationSettings}) async
```

**Example usage**:
```dart
    SahhaFlutter.configure(environment: SahhaEnvironment.sandbox)
        .then((success) => {debugPrint(success.toString())})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### isAuthenticated()

```dart
static Future<bool> isAuthenticated() async
```

**Example usage**:
```dart
SahhaFlutter.isAuthenticated().then((authenticated) => {
    if (authenticated == false)
    {
      // Authenticate the user
    }
});
```

### authenticate(...)

```dart
 static Future<bool> authenticate(
      {required String appId,
      required String appSecret,
      required String externalId}) async
```

**Example usage**:
```dart
    SahhaFlutter.authenticate(
        appId: APP_ID,
        appSecret: APP_SECRET,
        externalId: EXTERNAL_ID) // Some unique identifier for the user
        .then((success) =>
    {
      if (success) {
        // E.g. continue onboarding flow
      }
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### authenticateToken(...)

```dart
static Future<bool> authenticateToken(
    {required String profileToken,
    required String refreshToken}) async
```

**Example usage**:
```dart
    SahhaFlutter.authenticateToken(
        profileToken: PROFILE_TOKEN,
        refreshToken: REFRESH_TOKEN)
        .then((success) =>
    {
      if (success) {
        // E.g. continue onboarding flow
      }
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### deauthenticate()

```dart
static Future<bool> deauthenticate() async
```

**Example usage**:
```dart
    SahhaFlutter.deauthenticate()
        .then((success) =>
    {
      if (success) {
        // E.g. continue logic for successful deauthentication
      }
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getProfileToken()

```dart
static Future<String?> getProfileToken() async
```

**Example usage**:
```dart
    SahhaFlutter.getProfileToken()
        .then((token) =>
    {
      // Do something with the token
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});

```

---

### getDemographic()

```dart
static Future<String?> getDemographic() async
```

**Example usage**:
```dart
SahhaFlutter.getDemographic()
        .then((demographic) => {debugPrint(demographic)})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### postDemographic(...)

```dart
static Future<bool> postDemographic(Map demographic) async
```

**Example usage**:
```dart
const demographic = {'age': 123, 'gender': 'Male'};

SahhaFlutter.postDemographic(demographic)
    .then((success) => {debugPrint(success.toString())})
    .catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getSensorStatus(...)

```dart
static Future<SahhaSensorStatus> getSensorStatus(
      List<SahhaSensor> sensors) async
```

**Example usage**
```dart
const sensors = [SahhaSensor.sleep, SahhaSensor.steps, SahhaSensor.heart_rate];

SahhaFlutter.getSensorStatus(sensors)
    .then((status) => {debugPrint(status.toString())})
    .catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### enableSensors(...)

```dart
static Future<SahhaSensorStatus> enableSensors(
      List<SahhaSensor> sensors) async
```

**Example usage**:
```dart
const sensors = [SahhaSensor.sleep, SahhaSensor.steps, SahhaSensor.heart_rate];

SahhaFlutter.enableSensors(sensors)
    .then((status) => {debugPrint(status.toString())})
    .catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getScores(...)

```dart
static Future<String> getScores(
      {required List<SahhaScoreType> types,
      required DateTime startDateTime,
      required DateTime endDateTime}) async
```

**Example usage**:
```dart
    const types = [
      SahhaScoreType.activity,
      SahhaScoreType.sleep,
      SahhaScoreType.wellbeing
    ];

    SahhaFlutter.getScores(
        types: types,
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now())
        .then((value) {
      debugPrint(value.toString()); // value is in the form of a JSON array
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getBiomarkers(...)

```dart
static Future<String> getBiomarkers(
      {required List<SahhaBiomarkerCategory> categories,
      required List<SahhaBiomarkerType> types,
      required DateTime startDateTime,
      required DateTime endDateTime}) async
```

**Example usage**:
```dart
    const cateories = [
      SahhaBiomarkerCategory.activity,
      SahhaBiomarkerCategory.sleep,
    ];

    const types = [
      SahhaBiomarkerType.steps,
      SahhaBiomarkerType.sleep_duration,
      SahhaBiomarkerType.sleep_start_time,
      SahhaBiomarkerType.sleep_end_time,
    ];

    SahhaFlutter.getBiomarkers(
        categories: categories,
        types: types,
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now())
        .then((value) {
      debugPrint(value.toString()); // value is in the form of a JSON array
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getStats(...)

```dart
static Future<String> getStats(
      {required SahhaSensor sensor,
      required DateTime startDateTime,
      required DateTime endDateTime}) async
```

**Example usage**:
```dart
    // Stats for past week
    var start = DateTime.timestamp().subtract(const Duration(days: 7));
    var end = DateTime.timestamp();

    SahhaFlutter.getStats(
        sensor: SahhaSensor.steps, startDateTime: start, endDateTime: end)
        .then((value) {
      debugPrint(value.toString());
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

---

### getSamples(...)

```dart
static Future<String> getSamples(
      {required SahhaSensor sensor,
      required DateTime startDateTime,
      required DateTime endDateTime}) async
```

**Example usage**:
```dart
    // Samples for past week
    var start = DateTime.timestamp().subtract(const Duration(days: 7));
    var end = DateTime.timestamp();

    SahhaFlutter.getSamples(
            sensor: SahhaSensor.steps, startDateTime: start, endDateTime: end)
        .then((value) {
      debugPrint(value.toString());
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
```

### openAppSettings()
```dart
static void openAppSettings()
```

**Example usage**:
```dart
// This method is useful when the user denies permissions multiple times -- where the prompt will no longer show
    if (status == SahhaSensorStatus.disabled) {
      SahhaFlutter.openAppSettings();
    }
```

### Enums

#### SahhaEnvironment

```dart
enum SahhaEnvironment { 
  sandbox, 
  production 
}
```

#### SahhaSensor

```dart
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
```

#### SahhaSensorStatus

```dart
enum SahhaSensorStatus {
  pending,
  unavailable,
  disabled,
  enabled
}
```

#### SahhaScoreType

```dart
enum SahhaScoreType {
  wellbeing,
  activity,
  sleep,
  readiness,
  mental_wellbeing,
}
```

#### SahhaBiomarkerCategory

```dart
enum SahhaBiomarkerCategory {
  activity,
  body,
  characteristic,
  reproductive,
  sleep,
  vitals
}
```

#### SahhaBiomarkerType

```dart
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
```

</docgen-api>

---

Copyright © 2022 - 2023 Sahha. All rights reserved.
