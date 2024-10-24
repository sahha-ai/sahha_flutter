## 1.0.3

### Added

n/a

### Changed

n/a

### Fixed

- (Android) Resolved an issue where applying metadata to native sleep data could cause crashing

---

## 1.0.2

### Added

- (Android) Added metadata to logs
- (Android) Added `appVersion` to device information

### Changed

n/a

### Fixed

- (Android) Fixed an issue where the `endDateTime` timestamps were incorrect for historical step data

---

## 1.0.1

### Added

n/a

### Changed

n/a

### Fixed

- (Android) Resolved an issue where under certain circumstances, native step data would stop collecting (Health Connect step data unrelated)
- (Android) Resolved an issue where certain permission states were incorrectly returning `unavailable` specifically for Android version 9 (API 28)

---

## 1.0.0

### Added

- Added `getScores` method

### Changed

- Removed `analyze` method

### Fixed

- Fixed recording method strings
- (Android) Fixed a bug where in specific scenarios, incorrect permission statuses were returned
- (Android) Fixed a data filtering bug

---

## 0.4.5 alpha

### Added

- (Android) Improved the quality of step data being sent to Sahha API

### Changed

-  Changed `getSensorStatus` and `enableSensors` method parameters to require an explicit list of sensors

### Fixed

- (iOS) Delete credentials if API response is unauthorized
- (Android) Fixed a bug where the foreground service would attempt to periodically restart
- (Android) Fixed a minor bug when batching data

---

## 0.4.4 alpha

### Added

- n/a

### Changed

- (iOS) Moved data handling and posting to a dedicated data manager
- (Android) Improved data handling and posting

### Fixed

- (iOS) Fixed missing device information for logging
- (iOS) Fixed warnings for missing credentials
- (Android) Fixed deauthentication to properly halt background tasks and reset data

---

## 0.4.3 alpha

### Added

- n/a

### Changed

- n/a

### Fixed

- (iOS) Fixed crash when configuring sensors
- (iOS) Fixed loop when trying to refresh auth token
- (iOS) Fixed deauthenticate method if credentials were missing

---

## 0.4.2 alpha

### Added

- n/a

### Changed

- Moved sensor configuration from the `configure` method to `getSensorStatus` and `enableSensors` methods

### Fixed

- n/a

---

## 0.4.1 alpha

### Added

- n/a

### Changed

- (Android) Improved how Health Connect is queried in the background, removing the need for exact alarms and its manifest permission

### Fixed

- (iOS) Fixed device info uploading duplicate entries 
- (iOS) Fixed HKObserverQuery callback not firing after error

---

## 0.4.0 alpha

### Added

- Added exercise sensor
- (iOS) Collected gender and birth date from HealthKit

### Changed

- Improved batching of sensor data uploads
- (Android) Permissions must be added manually by the developer to AndroidManifest.xml
- (Android) Improved how Health Connect data is queried
- (Android) Adjusted how sensor data percentages are formatted
- (iOS) Increased historical sensor data from 7 days to 30 days

### Fixed

- (Android) Fixed sleep value formatting
- (Android) Fixed a bug which caused diastolic blood pressure data to be missing

---

## 0.3.9 alpha

### Added

- n/a

### Changed

- (Android) Permissions must be added manually by the developer to AndroidManifest.xml
- (iOS) Using configure method with an empty sensor value returns a pending sensor status

### Fixed

- n/a

---

## 0.3.8 alpha

### Added

- n/a

### Changed

- (Android) Improvements to ensure important background tasks continue running
- (Android) Upgraded to latest Gradle version

### Fixed

- (Android) Fixed a bug that would sometimes crash on initial launch
- (Android) Fixed a bug that could lock up the UI on lower Android OS versions
- (Android) Fixed a bug where permission status would return disabled when it should be unavailable on lower Android OS versions

---

## 0.3.7 alpha

### Added

- n/a

### Changed

- (iOS) Deauthorize user if API returns 410 error code

### Fixed

- (iOS) Fixed frequency of some insights
- (Android) Fixed configuration callback error

---

## 0.3.5 alpha

### Added

- Added `temperature` SahhaSensor enum

### Changed

- n/a

### Fixed

- (iOS) Fixed some insights not posting correctly

---

## 0.3.4 alpha

### Added

- Added temperature sensor data
- Added additional error logging

### Changed

- Renamed data_types and insight_types to snake_case
- Removed manual postSensorData method

### Fixed

- (Android) Fixed some insights not posting correctly
- (Android) Fixed some demographics not posting correctly
- (iOS) Fixed some sensor data not posting correctly

---

## 0.3.3 alpha

### Added

- Added new sensor types
- Added new insights

### Changed

- Renamed `pedometer` sensor to `activity` sensor

### Fixed

- n/a

---

## 0.3.2 alpha

### Added

- (Android) Support for Health Connect on devices below Android 14

### Changed

- (iOS) Changed sleep stage enum values

### Fixed

- n/a

---

## 0.3.1 alpha

### Added

- (Android) Support for Health Connect on devices with Android 14

### Changed

- n/a

### Fixed

- n/a

---

## 0.3.0 alpha

### Added

- Added insights for sleep and steps

### Changed

- n/a

### Fixed

- n/a

---

## 0.2.4 alpha

### Added

- Added error logging
- Added authenticate via profileToken
- Added analyzeDateRange method

### Changed

- Changed library interface

### Fixed

- n/a

---

## 0.2.3 alpha

### Added

- n/a

### Changed

- n/a

### Fixed

- (Android) Fixed analyze call parameters

---

## 0.2.2 alpha

### Added

- n/a

### Changed

- Removed redundant includeSourceData for calling analyze

### Fixed

- (Android) Fixed an issue that would sometimes cause the configure method to hang

---

## 0.2.1 alpha

### Added

- n/a

### Changed

- (Android) Removed redundant sensor permissions from Android manifest
- (Android) Improved how data is sent to the server

### Fixed

- n/a

---

## 0.2.0 alpha

### Added

- Added `heart` and `blood` sensors

### Changed

- Changed `authenticate` method to take `appId, appSecret, externalId` as parameters

### Fixed

- n/a

---

## 0.1.6 alpha

### Added

- n/a

### Changed

- (iOS) Improved background sensor data collection

### Fixed

- n/a

---

## 0.1.5 alpha

### Added

- n/a

### Changed

- (iOS) lower minimum iOS version to 12

### Fixed

- n/a

---

## 0.1.4 alpha

### Added

- n/a

### Changed

- n/a

### Fixed

- (iOS) Configuration callback possibly fired multiple times

---

## 0.1.3 alpha

### Added

- n/a

### Changed

- n/a

### Fixed

- (Android) Fixed sleep receiver crashing

---

## 0.1.2 alpha

### Added

- Added user device information

### Changed

- n/a

### Fixed

- n/a

---

## 0.1.1 alpha

### Added

- Added callback to configure method

### Changed

- n/a

### Fixed

- n/a

---

## 0.1.0 alpha

### Added

- n/a

### Changed

- Refactored sensor methods

### Fixed

- n/a

---

## 0.0.7 alpha

### Added

- Custom notification settings for Android

### Changed

- n/a

### Fixed

- n/a

---

## 0.0.6 alpha

### Added

- Added more demographic parameters
- Added pedometer sensor
- Added an optional list of sensor data used for analyzation

### Changed

- n/a

### Fixed

- Fixed some issues with missing sensor data on Android and iOS

---

## 0.0.5 alpha

### Added

- n/a

### Changed

- Changed analyze method to use double instead of long for iOS

### Fixed

- n/a

---

## 0.0.4 alpha

### Added

- n/a

### Changed

- n/a

### Fixed

- Sensor permission error on Android

---

## 0.0.3 alpha

### Added

- Health sensor data updates while app is in background (iOS)
- Analyze endpoint takes an optional range of dates to include

### Changed

- n/a

### Fixed

- n/a

---

## 0.0.2 alpha

### Added

- n/a

### Changed

- Refactored Health Activity -> Sleep Sensor
- Refactored Motion Activity -> Pedometer Sensor

### Fixed

- n/a

---

## 0.0.1 alpha

### Added

- Authentication
- Demographic
- Health Activity
- Motion Activity
- Analyzation

### Changed

- n/a

### Fixed

- n/a
