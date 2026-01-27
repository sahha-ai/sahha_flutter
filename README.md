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

In the `AndroidManifest.xml` file, which can be found in `android` > `app` > `src` > `main`, declare Google Health Connect data types if required, e.g. sleep and step count.

More data types are available such as heart rate, workout / exercise, please refer to the links below for more information.

```xml
<!-- Sleep -->
<uses-permission android:name="android.permission.health.READ_SLEEP" />

<!-- Activity -->
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_FLOORS_CLIMBED" />
```

This is recommended if you'd like to retrieve Health Connect data from other health apps such as WHOOP, Garmin, Samsung Health etc.

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
- Also add `Privacy - Motion Usage Description` (`NSMotionUsageDescription`) key.
- Provide a description, such as: "*This app needs motion data to track your activity and provide health insights*."

  Or add the **Motion Usage Description** directly in your `Info.plist` file:

  ```xml
  <key>NSMotionUsageDescription</key>
  <string>This app needs motion data to track your activity and provide health insights</string>
  ```

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
  exercise
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
```

</docgen-api>

---

Copyright © 2022 - 2023 Sahha. All rights reserved.
