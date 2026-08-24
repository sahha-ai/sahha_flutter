import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Environments the native SDK understands.
///
/// The plugin's `SahhaEnvironment` enum only carries `sandbox` and
/// `production`, but its iOS bridge resolves whatever string it is handed
/// through `SahhaEnvironment(rawValue:)` — so the example app can reach
/// `development` over the plugin's own method channel without the plugin
/// needing a change. See [configureSahha].
enum SahhaEnvironmentOption {
  development,
  sandbox,
  production;

  String get label => switch (this) {
    SahhaEnvironmentOption.development => 'development',
    SahhaEnvironmentOption.sandbox => 'sandbox',
    SahhaEnvironmentOption.production => 'production',
  };

  String get host => switch (this) {
    SahhaEnvironmentOption.development => 'development-api.sahha.ai',
    SahhaEnvironmentOption.sandbox => 'sandbox-api.sahha.ai',
    SahhaEnvironmentOption.production => 'api.sahha.ai',
  };

  static SahhaEnvironmentOption fromName(String? name) {
    for (final option in SahhaEnvironmentOption.values) {
      if (option.name == name) return option;
    }
    return SahhaEnvironmentOption.development;
  }
}

/// App credentials injected at build time so they never live in the repo:
///
/// ```bash
/// flutter run --dart-define=SAHHA_APP_ID=... --dart-define=SAHHA_APP_SECRET=...
/// ```
///
/// These only seed the Authentication screen's empty fields. Anything typed in
/// on device is persisted by that screen and wins from then on.
class SahhaBuildCredentials {
  const SahhaBuildCredentials._();

  static const String appId = String.fromEnvironment('SAHHA_APP_ID');
  static const String appSecret = String.fromEnvironment('SAHHA_APP_SECRET');
  static const String externalId = String.fromEnvironment('SAHHA_EXTERNAL_ID');
}

/// Calls the plugin's `configure` over its own method channel.
///
/// This deliberately bypasses `SahhaFlutter.configure` — that wrapper's
/// parameter type cannot express `development`, and the plugin is out of scope
/// for this test harness. The payload below is byte-for-byte what the typed
/// wrapper sends.
Future<bool> configureSahha({
  required SahhaEnvironmentOption environment,
  bool enableMotionTrigger = false,
}) async {
  const channel = MethodChannel('sahha_flutter');
  final success = await channel.invokeMethod<bool>('configure', {
    'environment': environment.label,
    'notificationSettings': <String, String>{},
    'enableMotionTrigger': enableMotionTrigger,
  });
  return success ?? false;
}

/// Stress Lab flags that have to survive a force-quit, because the states they
/// set up are only reachable on a cold launch.
class StressLabSettings {
  StressLabSettings({
    required this.environment,
    required this.coldLaunchRace,
    required this.enableMotionTrigger,
  });

  static const String _environmentKey = 'stressLab.environment';
  static const String _coldLaunchRaceKey = 'stressLab.coldLaunchRace';
  static const String _motionTriggerKey = 'stressLab.enableMotionTrigger';

  /// Environment handed to the startup `configure()`.
  SahhaEnvironmentOption environment;

  /// When set, the startup `configure()` is followed immediately by an
  /// auth-gated call, without awaiting it (D1).
  bool coldLaunchRace;

  /// Feeds the startup `configure()` call (E4).
  bool enableMotionTrigger;

  static StressLabSettings defaults() => StressLabSettings(
    environment: SahhaEnvironmentOption.development,
    coldLaunchRace: false,
    enableMotionTrigger: false,
  );

  static Future<StressLabSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StressLabSettings(
        environment: SahhaEnvironmentOption.fromName(
          prefs.getString(_environmentKey),
        ),
        coldLaunchRace: prefs.getBool(_coldLaunchRaceKey) ?? false,
        enableMotionTrigger: prefs.getBool(_motionTriggerKey) ?? false,
      );
    } catch (error) {
      debugPrint('StressLab: reading settings failed -> $error');
      return defaults();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment.name);
    await prefs.setBool(_coldLaunchRaceKey, coldLaunchRace);
    await prefs.setBool(_motionTriggerKey, enableMotionTrigger);
  }
}

/// One sabotage method on the native chaos channel.
class ChaosMethod {
  const ChaosMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.scenario,
    this.needsRelaunch = false,
  });

  final String id;
  final String title;
  final String description;

  /// Scenario ID from the field test plan, for the on-screen label.
  final String scenario;

  /// Whether the sabotage only takes effect once the SDK re-reads storage.
  final bool needsRelaunch;
}

/// Read-only inspector, listed apart from the destructive methods.
const ChaosMethod inspectStorageMethod = ChaosMethod(
  id: 'inspectStorage',
  title: 'Inspect storage',
  description:
      'Sensor key type and decoded values, anchor counts by prefix, keychain '
      'item presence, deviceId, and the loaded Sahha framework.',
  scenario: 'verify',
);

const List<ChaosMethod> sensorStoreChaosMethods = [
  ChaosMethod(
    id: 'poisonStoreLegacy',
    title: 'Poison: legacy 1.3.7 names',
    description:
        'dietary_biotin, dietary_caffeine, dietary_fat_total, sleep, steps',
    scenario: 'A1',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'poisonStoreMixed',
    title: 'Poison: mixed unknown',
    description: 'steps, sleep, not_a_sensor',
    scenario: 'A2',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'poisonStoreAllUnknown',
    title: 'Poison: all unknown (downgrade)',
    description: 'from_the_future_a, from_the_future_b',
    scenario: 'A3',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'poisonStoreForeign',
    title: 'Poison: foreign value',
    description: 'Writes a plain String where the SDK expects Data',
    scenario: 'A4',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'poisonStoreGarbage',
    title: 'Poison: undecodable bytes',
    description: '32 random bytes under the sensors key',
    scenario: 'A5',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'relocateAnchorsToLegacyKeys',
    title: 'Relocate anchors to legacy keys',
    description:
        'Moves hkAnchor.* and hkAnchorDate.* to their pre-rename key names',
    scenario: 'A6',
    needsRelaunch: true,
  ),
];

const List<ChaosMethod> healthKitChaosMethods = [
  ChaosMethod(
    id: 'disableAllHKBackgroundDelivery',
    title: 'Disable all HK background delivery',
    description:
        'The app-wide HealthKit teardown an iOS update or restore performs',
    scenario: 'C2',
  ),
];

const List<ChaosMethod> tokenChaosMethods = [
  ChaosMethod(
    id: 'expireProfileToken',
    title: 'Expire profile token',
    description: 'Past exp, real refresh token kept — proactive refresh',
    scenario: 'D5a',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'expireProfileTokenSoon',
    title: 'Profile token expiring soon',
    description:
        'exp 5 minutes out: not expired, but inside the 30m proactive window',
    scenario: 'D5a',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'invalidateProfileToken',
    title: 'Invalidate profile token',
    description: 'exp 24h out, unusable signature — server 401, then refresh',
    scenario: 'D5b',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'expireRefreshToken',
    title: 'Expire refresh token',
    description: 'Past exp — session expires with no server round trip',
    scenario: 'D6a',
    needsRelaunch: true,
  ),
  ChaosMethod(
    id: 'invalidateBothTokens',
    title: 'Invalidate both tokens',
    description: 'Both future exp with unusable signatures — server-authoritative',
    scenario: 'D6b',
    needsRelaunch: true,
  ),
];

/// Wrapper over the Runner's `#if DEBUG` sabotage channel.
///
/// The channel is registered by the example app's own AppDelegate, so it exists
/// only in debug builds on iOS. Anywhere else, calls report as unavailable
/// rather than throwing an opaque MissingPluginException.
class ChaosChannel {
  const ChaosChannel._();

  static const MethodChannel _channel = MethodChannel(
    'sahha_flutter_example/chaos',
  );

  /// The channel is iOS-only and debug-only. Profile builds use the release
  /// xcconfig, so `#if DEBUG` excludes the channel there too.
  static bool get isSupported => kDebugMode && Platform.isIOS;

  static Future<Map<String, dynamic>> invoke(String method) async {
    if (!isSupported) {
      throw StateError(
        'The chaos channel is only registered in debug iOS builds.',
      );
    }
    final result = await _channel.invokeMapMethod<String, dynamic>(method);
    return result ?? <String, dynamic>{};
  }
}

/// Outcome of the most recent cold-launch race.
///
/// The race runs before any screen is mounted, so the result is persisted
/// rather than shown: the Stress Lab reads it back on the next visit.
class ColdLaunchRaceOutcome {
  const ColdLaunchRaceOutcome._();

  static const String _key = 'stressLab.lastColdLaunchRace';

  static Future<void> record(String outcome) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, '${DateTime.now().toIso8601String()}  $outcome');
    } catch (error) {
      debugPrint('StressLab: recording the cold-launch race failed -> $error');
    }
  }

  static Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (error) {
      debugPrint('StressLab: reading the cold-launch race failed -> $error');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
