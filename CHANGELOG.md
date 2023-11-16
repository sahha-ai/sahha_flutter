## 0.3.1 alpha

### Added

- (Android) Support for Health Connect on devices below Android 14

### Changed

- (iOS) Changed sleep stage enum values

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
