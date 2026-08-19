import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/services/stress_lab.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';

/// Puts the device into the broken states the 1.4.0-beta.3 remediation fixes,
/// so each one can be checked against a real phone rather than a unit test.
///
/// The destructive half is native: a debug-only channel in the example app's
/// own Runner writes the same UserDefaults keys, keychain items and app-wide
/// HealthKit state a bad upgrade or an OS restore would. Nothing here reaches
/// into SDK internals, so every state produced is one a device can reach on
/// its own.
class StressLabView extends StatefulWidget {
  const StressLabView({super.key});

  @override
  State<StressLabView> createState() => StressLabState();
}

class StressLabState extends State<StressLabView> {
  /// The regression D1 exists to catch: this message from an auth-gated call
  /// while a profile is signed in means configure lost the race.
  static const String _unauthorizedMessage =
      'Unauthorized. Please call `Sahha.authenticate(...)` first.';

  static const int _maxLogEntries = 80;
  static final DateFormat _logTimeFormat = DateFormat('HH:mm:ss.SSS');
  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  StressLabSettings _settings = StressLabSettings.defaults();
  bool _settingsLoaded = false;

  final Set<String> _busy = {};
  final List<_LogEntry> _log = [];

  String? _lastInspection;
  String? _lastRaceOutcome;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
    unawaited(_loadRaceOutcome());
  }

  // ---------------------------------------------------------------- logging

  void _appendLog(String message, {bool isError = false}) {
    final entry = _LogEntry(
      _logTimeFormat.format(DateTime.now()),
      message,
      isError,
    );
    if (!mounted) return;
    setState(() {
      _log.insert(0, entry);
      if (_log.length > _maxLogEntries) {
        _log.removeRange(_maxLogEntries, _log.length);
      }
    });
  }

  /// Logs a failure, and calls out the launch-race regression by name when the
  /// SDK's unauthorized message comes back from an auth-gated call.
  void _logCallFailure(String action, Object error) {
    final text = error.toString();
    if (text.contains(_unauthorizedMessage)) {
      _appendLog(
        '$action -> D1 REGRESSION: auth-gated call was rejected as '
        'unauthorized while a profile is signed in',
        isError: true,
      );
    } else {
      _appendLog('$action FAILED: $text', isError: true);
    }
    debugPrint('StressLab: $action failed -> $text');
  }

  void _reportError(String action, Object error, {String? subtitle}) {
    _logCallFailure(action, error);
    if (!mounted) return;
    unawaited(
      showResponseSheet(
        context,
        title: '$action failed',
        subtitle: subtitle,
        body: error.toString(),
        isError: true,
      ),
    );
  }

  Future<void> _runBusy(String key, Future<void> Function() action) async {
    if (_busy.contains(key) || !mounted) return;
    setState(() => _busy.add(key));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  // ------------------------------------------------------------- settings

  Future<void> _loadSettings() async {
    final settings = await StressLabSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _settingsLoaded = true;
    });
    _appendLog(
      'Startup settings: environment=${settings.environment.label}, '
      'coldLaunchRace=${settings.coldLaunchRace}, '
      'enableMotionTrigger=${settings.enableMotionTrigger}',
    );
  }

  Future<void> _loadRaceOutcome() async {
    final outcome = await ColdLaunchRaceOutcome.read();
    if (!mounted || outcome == null) return;
    setState(() => _lastRaceOutcome = outcome);
    _appendLog('Last cold-launch race: $outcome');
  }

  Future<void> _persistSettings(String change) async {
    try {
      await _settings.save();
      _appendLog('$change — applies on the next launch');
    } catch (error) {
      _appendLog('Could not save settings: $error', isError: true);
    }
  }

  // ------------------------------------------------------- races and abuse

  /// D1 warm race: configure and an auth-gated call fired back to back, with
  /// configure deliberately not awaited.
  void _raceConfigureAndGatedCall() {
    _appendLog('D1 race: configure() then getScores(), configure not awaited');

    final now = DateTime.now();
    final configureFuture = configureSahha(
      environment: _settings.environment,
      enableMotionTrigger: _settings.enableMotionTrigger,
    );
    final scoresFuture = SahhaFlutter.getScores(
      types: [SahhaScoreType.wellbeing],
      startDateTime: now.subtract(const Duration(days: 7)),
      endDateTime: now,
    );

    unawaited(
      configureFuture
          .then((success) => _appendLog('race configure() -> $success'))
          .catchError((Object error) => _logCallFailure('race configure()', error)),
    );
    unawaited(
      scoresFuture
          .then(
            (value) => _appendLog(
              'race getScores() -> ${_summariseResponse(value)}',
            ),
          )
          .catchError((Object error) => _logCallFailure('race getScores()', error)),
    );
  }

  /// D3: a real upload in flight, torn down mid-request.
  Future<void> _deauthDuringUpload() async {
    _appendLog('D3: postSensorData(), then deauthenticate() in 300ms');
    SahhaFlutter.postSensorData();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final success = await SahhaFlutter.deauthenticate();
      _appendLog('D3 deauthenticate() -> $success');
    } catch (error) {
      _reportError('D3 deauthenticate()', error);
    }
  }

  /// D4: five concurrent deauthentications. Every one must succeed.
  Future<void> _deauthHammer() async {
    const count = 5;
    _appendLog('D4: $count concurrent deauthenticate() calls');
    final results = await Future.wait([
      for (var index = 0; index < count; index++)
        SahhaFlutter.deauthenticate()
            .then<Object>((success) => success)
            .catchError((Object error) => error),
    ]);

    var failures = 0;
    for (var index = 0; index < results.length; index++) {
      final result = results[index];
      if (result is bool) {
        _appendLog('D4 call ${index + 1}/$count -> $result');
      } else {
        failures++;
        _logCallFailure('D4 call ${index + 1}/$count', result);
      }
    }
    _appendLog(
      failures == 0
          ? 'D4 -> all $count calls succeeded'
          : 'D4 -> $failures of $count calls failed',
      isError: failures != 0,
    );
  }

  /// Observation only: sequential configures build a fresh container without
  /// disposing the previous one. Recorded, never a gate.
  Future<void> _repeatConfigure() async {
    _appendLog('Repeat configure: two sequential configure() calls');
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final success = await configureSahha(
          environment: _settings.environment,
          enableMotionTrigger: _settings.enableMotionTrigger,
        );
        _appendLog('configure() $attempt/2 -> $success');
      } catch (error) {
        _reportError('configure() $attempt/2', error);
        return;
      }
    }
    _appendLog(
      'Watch the console: the previous container is not disposed, so its '
      'observers and tasks keep running. Known open item, not a beta.3 gate.',
    );
  }

  static String _summariseResponse(String value) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 80) return collapsed;
    return '${collapsed.substring(0, 80)}… (${value.length} chars)';
  }

  // ------------------------------------------------------------------ chaos

  Future<void> _runChaos(ChaosMethod method) async {
    if (!ChaosChannel.isSupported) {
      _appendLog(
        '${method.id} skipped — the chaos channel needs a debug iOS build',
        isError: true,
      );
      return;
    }
    _appendLog('${method.scenario} ${method.id} requested');
    try {
      final result = await ChaosChannel.invoke(method.id);
      final rendered = _prettyJson.convert(result);
      _appendLog('${method.id} -> ${_summariseResponse(rendered)}');
      if (method.id == inspectStorageMethod.id) {
        if (mounted) setState(() => _lastInspection = rendered);
      } else if (method.needsRelaunch) {
        _appendLog(
          '${method.id}: force-quit and relaunch — the SDK only re-reads '
          'storage on a cold launch',
        );
      }
    } catch (error) {
      _reportError(method.id, error, subtitle: 'scenario ${method.scenario}');
    }
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Stress Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildIntroCard(theme),
          _sectionHeader(theme, 'Startup configuration'),
          _buildStartupCard(theme),
          _sectionHeader(theme, 'Races and lifecycle abuse'),
          _buildRacesCard(theme),
          _sectionHeader(theme, 'Sensor store'),
          _buildChaosCard(theme, sensorStoreChaosMethods),
          _sectionHeader(theme, 'HealthKit'),
          _buildChaosCard(theme, healthKitChaosMethods),
          _sectionHeader(theme, 'Tokens'),
          _buildChaosCard(theme, tokenChaosMethods),
          _sectionHeader(theme, 'Inspector'),
          _buildInspectorCard(theme),
          _sectionHeader(
            theme,
            'Activity log',
            actions: [
              Text(
                '${_log.length}/$_maxLogEntries',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Clear log',
                onPressed: _log.isEmpty ? null : () => setState(_log.clear),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          _buildLogCard(theme),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme,
    String title, {
    List<Widget> actions = const [],
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 24, actions.isEmpty ? 4 : 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    final supported = ChaosChannel.isSupported;
    final color = supported ? theme.colorScheme.primary : Colors.orange.shade800;
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              supported ? Icons.science_outlined : Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                supported
                    ? 'Sabotage writes only public storage the SDK reads: '
                          'UserDefaults keys, keychain items and app-wide '
                          'HealthKit APIs. Most states need a force-quit before '
                          'the SDK re-reads them.'
                    : 'The native chaos channel is registered only in debug iOS '
                          'builds. The race, deauth and configure controls below '
                          'still work; the sabotage buttons do not.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartupCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Environment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Handed to the startup configure(). '
                  '${_settings.environment.host}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in SahhaEnvironmentOption.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: _settings.environment == option,
                        onSelected: !_settingsLoaded
                            ? null
                            : (selected) {
                                if (!selected) return;
                                setState(() => _settings.environment = option);
                                unawaited(
                                  _persistSettings(
                                    'Environment set to ${option.label}',
                                  ),
                                );
                              },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          SwitchListTile(
            value: _settings.coldLaunchRace,
            onChanged: !_settingsLoaded
                ? null
                : (value) {
                    setState(() => _settings.coldLaunchRace = value);
                    unawaited(
                      _persistSettings(
                        'Cold-launch race ${value ? 'enabled' : 'disabled'}',
                      ),
                    );
                  },
            title: const Text('Cold-launch race'),
            subtitle: Text(
              'Fires getScores() straight after the startup configure(), '
              'without awaiting it. D1.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (_lastRaceOutcome != null) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.history_toggle_off,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                'Last cold-launch race',
                style: theme.textTheme.bodySmall,
              ),
              subtitle: Text(
                _lastRaceOutcome!,
                style: monoStyle(context, fontSize: 11),
              ),
              trailing: IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () async {
                  await ColdLaunchRaceOutcome.clear();
                  if (!mounted) return;
                  setState(() => _lastRaceOutcome = null);
                },
              ),
            ),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            value: _settings.enableMotionTrigger,
            onChanged: !_settingsLoaded
                ? null
                : (value) {
                    setState(() => _settings.enableMotionTrigger = value);
                    unawaited(
                      _persistSettings(
                        'enableMotionTrigger ${value ? 'enabled' : 'disabled'}',
                      ),
                    );
                  },
            title: const Text('enableMotionTrigger'),
            subtitle: Text(
              'The one documented prompt outside the HealthKit funnel — a '
              'separate Motion & Fitness sheet. E4.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacesCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _actionTile(
            theme,
            icon: Icons.flash_on_outlined,
            title: 'Race: configure → gated call',
            description:
                'configure() and getScores() back to back, configure not '
                'awaited. Never expect the unauthorized message.',
            scenario: 'D1',
            onTap: _raceConfigureAndGatedCall,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            theme,
            icon: Icons.cloud_off_outlined,
            title: 'Deauth during upload',
            description:
                'postSensorData(), then deauthenticate() 300ms later. Expect '
                'no max-retry error from the cancelled flight.',
            scenario: 'D3',
            busyKey: 'deauthUpload',
            onTap: () => unawaited(
              _runBusy('deauthUpload', _deauthDuringUpload),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            theme,
            icon: Icons.repeat_outlined,
            title: 'Deauth hammer (5 concurrent)',
            description: 'Five concurrent deauthenticate() calls, all of which '
                'must succeed.',
            scenario: 'D4',
            busyKey: 'deauthHammer',
            onTap: () => unawaited(_runBusy('deauthHammer', _deauthHammer)),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            theme,
            icon: Icons.settings_backup_restore_outlined,
            title: 'Repeat configure ×2',
            description:
                'Two sequential configure() calls. Observation only — record '
                'what the console shows, do not fail the run on it.',
            scenario: 'note',
            busyKey: 'repeatConfigure',
            onTap: () =>
                unawaited(_runBusy('repeatConfigure', _repeatConfigure)),
          ),
        ],
      ),
    );
  }

  Widget _buildChaosCard(ThemeData theme, List<ChaosMethod> methods) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final method in methods) ...[
            if (method != methods.first)
              const Divider(height: 1, indent: 16, endIndent: 16),
            _actionTile(
              theme,
              icon: Icons.bolt_outlined,
              title: method.title,
              description: method.description,
              scenario: method.scenario,
              busyKey: method.id,
              enabled: ChaosChannel.isSupported,
              onTap: () => unawaited(
                _runBusy(method.id, () => _runChaos(method)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInspectorCard(ThemeData theme) {
    final inspection = _lastInspection;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _actionTile(
            theme,
            icon: Icons.travel_explore_outlined,
            title: inspectStorageMethod.title,
            description: inspectStorageMethod.description,
            scenario: inspectStorageMethod.scenario,
            busyKey: inspectStorageMethod.id,
            enabled: ChaosChannel.isSupported,
            onTap: () => unawaited(
              _runBusy(
                inspectStorageMethod.id,
                () => _runChaos(inspectStorageMethod),
              ),
            ),
          ),
          if (inspection != null) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    inspection,
                    style: monoStyle(context, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required String scenario,
    required VoidCallback onTap,
    String? busyKey,
    bool enabled = true,
  }) {
    final busy = busyKey != null && _busy.contains(busyKey);
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(description, style: theme.textTheme.bodySmall),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _scenarioChip(theme, scenario),
      onTap: busy || !enabled ? null : onTap,
    );
  }

  Widget _scenarioChip(ThemeData theme, String scenario) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        scenario,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildLogCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _log.isEmpty
              ? [
                  Text(
                    'Nothing yet. Every action and result is logged here, '
                    'newest first.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ]
              : [
                  for (final entry in _log)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${entry.time}  ${entry.message}',
                        style: monoStyle(context, fontSize: 11).copyWith(
                          color: entry.isError ? theme.colorScheme.error : null,
                        ),
                      ),
                    ),
                ],
        ),
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry(this.time, this.message, this.isError);

  final String time;
  final String message;
  final bool isError;
}
