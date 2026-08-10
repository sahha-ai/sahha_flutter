import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/multi_select_sheet.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:sahha_flutter_example/widgets/sensor_groups.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-stop screen for answering "why is my data not flowing?" on a device:
/// authentication + platform + combined sensor status, a per-sensor status
/// matrix, the three side-effecting SDK calls, and an on-screen activity log
/// so the maintainer does not need the Xcode/adb console.
class SensorDiagnosticsView extends StatefulWidget {
  const SensorDiagnosticsView({super.key});

  @override
  State<SensorDiagnosticsView> createState() => SensorDiagnosticsState();
}

class SensorDiagnosticsState extends State<SensorDiagnosticsView> {
  /// Sensors under test, persisted as enum-name strings.
  static const String _prefsKey = 'diagnostics.sensors';

  /// A pragmatic default: the sensors most demos actually depend on.
  static const List<SahhaSensor> _defaultSensors = <SahhaSensor>[
    SahhaSensor.sleep,
    SahhaSensor.steps,
    SahhaSensor.heart_rate,
    SahhaSensor.resting_heart_rate,
    SahhaSensor.heart_rate_variability_sdnn,
    SahhaSensor.active_energy_burned,
    SahhaSensor.floors_climbed,
    SahhaSensor.exercise,
  ];

  static const int _maxLogEntries = 50;
  static final DateFormat _logTimeFormat = DateFormat('HH:mm:ss');

  List<SahhaSensor> _sensors = List<SahhaSensor>.of(_defaultSensors);

  bool _authBusy = false;
  bool? _isAuthenticated;

  bool _combinedBusy = false;
  SahhaSensorStatus? _combinedStatus;

  final Map<SahhaSensor, SahhaSensorStatus> _statuses = {};
  final Set<SahhaSensor> _querying = {};

  bool _enableBusy = false;
  SahhaSensorStatus? _enableResult;
  String? _postResult;
  String? _settingsResult;

  final List<_LogEntry> _logEntries = [];

  @override
  void initState() {
    super.initState();
    _restoreSensors().then((_) => _refreshAll());
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
      _logEntries.insert(0, entry);
      if (_logEntries.length > _maxLogEntries) {
        _logEntries.removeRange(_maxLogEntries, _logEntries.length);
      }
    });
  }

  /// Hard failures get a log line, a device-log line and a response sheet.
  void _reportError(String action, Object error, {String? subtitle}) {
    debugPrint('Diagnostics: $action failed -> $error');
    _appendLog('$action FAILED: $error', isError: true);
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

  // ------------------------------------------------------------ persistence

  Future<void> _restoreSensors() async {
    List<String>? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getStringList(_prefsKey);
    } catch (error) {
      debugPrint('Diagnostics: reading $_prefsKey failed -> $error');
      _appendLog('Could not read saved sensors: $error', isError: true);
      return;
    }
    if (saved == null) return;

    final byName = {
      for (final sensor in SahhaSensor.values) sensor.name: sensor,
    };
    final restored = <SahhaSensor>[];
    final unknown = <String>[];
    for (final name in saved) {
      final sensor = byName[name];
      if (sensor == null) {
        unknown.add(name);
      } else if (!restored.contains(sensor)) {
        restored.add(sensor);
      }
    }
    if (unknown.isNotEmpty) {
      _appendLog('Ignored unknown saved sensors: ${unknown.join(', ')}');
    }
    if (!mounted) return;
    setState(() => _sensors = restored);
  }

  Future<void> _persistSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [
        for (final sensor in _sensors) sensor.name,
      ]);
    } catch (error) {
      debugPrint('Diagnostics: writing $_prefsKey failed -> $error');
      _appendLog('Could not save sensor selection: $error', isError: true);
    }
  }

  // --------------------------------------------------------------- checking

  Future<void> _refreshAll() async {
    _appendLog('Running all diagnostics checks');
    await Future.wait([
      _refreshAuthentication(),
      _refreshCombinedStatus(),
      _refreshMatrix(),
    ]);
  }

  Future<void> _refreshAuthentication() async {
    if (!mounted) return;
    setState(() => _authBusy = true);
    try {
      final value = await SahhaFlutter.isAuthenticated();
      debugPrint('Diagnostics: isAuthenticated() -> $value');
      if (!mounted) return;
      setState(() {
        _isAuthenticated = value;
        _authBusy = false;
      });
      _appendLog('isAuthenticated() -> $value');
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAuthenticated = null;
          _authBusy = false;
        });
      }
      _reportError('isAuthenticated()', error);
    }
  }

  Future<void> _refreshCombinedStatus() async {
    if (!mounted) return;
    final sensors = List<SahhaSensor>.of(_sensors);
    if (sensors.isEmpty) {
      setState(() {
        _combinedStatus = null;
        _combinedBusy = false;
      });
      return;
    }
    setState(() => _combinedBusy = true);
    try {
      final status = await SahhaFlutter.getSensorStatus(sensors);
      debugPrint(
        'Diagnostics: getSensorStatus(${sensors.length} sensors) -> ${status.name}',
      );
      if (!mounted) return;
      setState(() {
        _combinedStatus = status;
        _combinedBusy = false;
      });
      _appendLog(
        'getSensorStatus(${sensors.length} sensors) -> ${status.name}',
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _combinedStatus = null;
          _combinedBusy = false;
        });
      }
      _reportError('getSensorStatus(${sensors.length} sensors)', error);
    }
  }

  /// getSensorStatus returns ONE combined status for a set, so the matrix is
  /// built from one single-sensor call per row.
  Future<Object?> _querySensorStatus(SahhaSensor sensor) async {
    if (!mounted) return null;
    setState(() => _querying.add(sensor));
    try {
      final status = await SahhaFlutter.getSensorStatus([sensor]);
      debugPrint(
        'Diagnostics: getSensorStatus([${sensor.name}]) -> ${status.name}',
      );
      if (!mounted) return null;
      setState(() {
        _statuses[sensor] = status;
        _querying.remove(sensor);
      });
      _appendLog('${sensor.name} -> ${status.name}');
      return null;
    } catch (error) {
      debugPrint('Diagnostics: getSensorStatus([${sensor.name}]) -> $error');
      if (mounted) {
        setState(() {
          _statuses.remove(sensor);
          _querying.remove(sensor);
        });
      }
      _appendLog('${sensor.name} FAILED: $error', isError: true);
      return error;
    }
  }

  Future<void> _refreshMatrix() async {
    if (!mounted) return;
    final sensors = List<SahhaSensor>.of(_sensors);
    if (sensors.isEmpty) {
      setState(_statuses.clear);
      return;
    }
    final results = await Future.wait(sensors.map(_querySensorStatus));
    final failures = results.whereType<Object>().toList();
    if (failures.isEmpty) return;
    if (!mounted) return;
    // One sheet for the batch, not one per failing sensor.
    unawaited(
      showResponseSheet(
        context,
        title: 'getSensorStatus failed',
        subtitle: '${failures.length} of ${sensors.length} sensors',
        body: failures.map((error) => error.toString()).join('\n\n'),
        isError: true,
      ),
    );
  }

  Future<void> _refreshSensor(SahhaSensor sensor) async {
    final error = await _querySensorStatus(sensor);
    if (error == null) return;
    if (!mounted) return;
    unawaited(
      showResponseSheet(
        context,
        title: 'getSensorStatus failed',
        subtitle: sensor.name,
        body: error.toString(),
        isError: true,
      ),
    );
  }

  // ---------------------------------------------------------------- actions

  Future<void> _editSensors() async {
    final selection = await showMultiSelectSheet<SahhaSensor>(
      context: context,
      title: 'Sensors under test',
      options: sensorsGroupedInEnumOrder(),
      initialSelection: _sensors.toSet(),
      labelOf: (sensor) => sensor.name,
      groupOf: sensorGroupOf,
    );
    if (selection == null || !mounted) return;
    // Keep groups contiguous by reusing the grouped enum order.
    final ordered = [
      for (final sensor in sensorsGroupedInEnumOrder())
        if (selection.contains(sensor)) sensor,
    ];
    setState(() {
      _sensors = ordered;
      _statuses.removeWhere((sensor, _) => !selection.contains(sensor));
    });
    _appendLog('Sensors under test: ${ordered.length} selected');
    await _persistSensors();
    await Future.wait([_refreshCombinedStatus(), _refreshMatrix()]);
  }

  Future<void> _enableSensors() async {
    if (!mounted) return;
    final sensors = List<SahhaSensor>.of(_sensors);
    if (sensors.isEmpty) {
      _appendLog('enableSensors() skipped — no sensors selected');
      return;
    }
    setState(() => _enableBusy = true);
    _appendLog('enableSensors(${sensors.length} sensors) requested');
    try {
      final status = await SahhaFlutter.enableSensors(sensors);
      debugPrint(
        'Diagnostics: enableSensors(${sensors.length} sensors) -> ${status.name}',
      );
      if (!mounted) return;
      setState(() {
        _enableBusy = false;
        _enableResult = status;
      });
      _appendLog('enableSensors() -> ${status.name}');
      await Future.wait([_refreshCombinedStatus(), _refreshMatrix()]);
    } catch (error) {
      if (mounted) setState(() => _enableBusy = false);
      _reportError('enableSensors(${sensors.length} sensors)', error);
    }
  }

  void _postSensorData() {
    SahhaFlutter.postSensorData();
    debugPrint('Diagnostics: postSensorData() called — fire and forget');
    setState(
      () => _postResult = 'Requested ${_logTimeFormat.format(DateTime.now())}',
    );
    _appendLog(
      'postSensorData() called — fire-and-forget (void, no result callback)',
    );
  }

  void _openAppSettings() {
    SahhaFlutter.openAppSettings();
    debugPrint('Diagnostics: openAppSettings() called');
    setState(
      () => _settingsResult = 'Opened ${_logTimeFormat.format(DateTime.now())}',
    );
    _appendLog('openAppSettings() called — check the OS permission screen');
  }

  Future<void> _openAuthentication() async {
    await Navigator.of(context).pushNamed('/authentication');
    if (!mounted) return;
    await _refreshAuthentication();
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Diagnostics')),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Pull down to re-run every check on this device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(theme),
            _sectionHeader(
              theme,
              'Sensor status',
              actions: [
                TextButton.icon(
                  onPressed: _editSensors,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Edit sensors'),
                ),
                IconButton(
                  tooltip: 'Refresh all',
                  onPressed: _refreshMatrix,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            _buildMatrixCard(theme),
            _sectionHeader(theme, 'Actions'),
            _buildActionsCard(theme),
            _sectionHeader(
              theme,
              'Activity log',
              actions: [
                Text(
                  '${_logEntries.length}/$_maxLogEntries',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Clear log',
                  onPressed: _logEntries.isEmpty
                      ? null
                      : () => setState(_logEntries.clear),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _buildLogCard(theme),
          ],
        ),
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
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final authenticated = _isAuthenticated;
    final String authTitle;
    final String authSubtitle;
    if (_authBusy) {
      authTitle = 'Checking authentication…';
      authSubtitle = 'isAuthenticated()';
    } else if (authenticated == true) {
      authTitle = 'Authenticated';
      authSubtitle = 'A profile is signed in, so data can be posted.';
    } else if (authenticated == false) {
      authTitle = 'Not authenticated';
      authSubtitle = 'No data will flow. Tap to authenticate a profile.';
    } else {
      authTitle = 'Authentication unknown';
      authSubtitle = 'isAuthenticated() failed. Tap to open Authentication.';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: _authBusy
                ? const _RowSpinner()
                : Icon(
                    authenticated == true
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: authenticated == true
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                  ),
            title: Text(authTitle),
            subtitle: Text(authSubtitle, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openAuthentication,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Platform.isIOS ? Icons.phone_iphone : Icons.phone_android,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(Platform.operatingSystem),
            subtitle: Text(
              Platform.operatingSystemVersion,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.sensors,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text('Combined sensor status'),
            subtitle: Text(
              _sensors.isEmpty
                  ? 'No sensors selected'
                  : 'One getSensorStatus() call for all '
                        '${_sensors.length} selected sensors',
              style: theme.textTheme.bodySmall,
            ),
            trailing: _combinedBusy
                ? const _RowSpinner()
                : _statusChip(theme, _combinedStatus),
            onTap: _refreshCombinedStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCard(ThemeData theme) {
    if (_sensors.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            Icons.playlist_add,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: const Text('No sensors under test'),
          subtitle: Text(
            'Tap "Edit sensors" to pick the sensors to check.',
            style: theme.textTheme.bodySmall,
          ),
          onTap: _editSensors,
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final sensor in _sensors) ...[
            if (sensor != _sensors.first)
              const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              dense: true,
              title: Text(sensor.name),
              subtitle: Text(
                sensorGroupOf(sensor),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: _querying.contains(sensor)
                  ? const _RowSpinner()
                  : _statusChip(theme, _statuses[sensor]),
              onTap: () => _refreshSensor(sensor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _actionTile(
            theme,
            icon: Icons.toggle_on_outlined,
            title: 'Enable selected sensors',
            description:
                'enableSensors() prompts for permission, then re-checks status.',
            busy: _enableBusy,
            result: _enableResult == null
                ? null
                : _statusChip(theme, _enableResult),
            onTap: _enableSensors,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            theme,
            icon: Icons.cloud_upload_outlined,
            title: 'Post sensor data',
            description:
                'postSensorData() is fire-and-forget — it returns no result.',
            resultText: _postResult,
            onTap: _postSensorData,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            theme,
            icon: Icons.settings_outlined,
            title: 'Open app settings',
            description:
                'openAppSettings() opens the OS permission screen for this app.',
            resultText: _settingsResult,
            onTap: _openAppSettings,
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool busy = false,
    Widget? result,
    String? resultText,
  }) {
    final feedback =
        result ??
        (resultText == null
            ? null
            : Text(
                resultText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ));
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(description, style: theme.textTheme.bodySmall),
      trailing: busy ? const _RowSpinner() : feedback,
      onTap: busy ? null : onTap,
    );
  }

  Widget _buildLogCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _logEntries.isEmpty
              ? [
                  Text(
                    'Nothing yet. Every action and result is logged here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ]
              : [
                  for (final entry in _logEntries)
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

  Widget _statusChip(ThemeData theme, SahhaSensorStatus? status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status?.name ?? 'not checked',
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Color _statusColor(SahhaSensorStatus? status) => switch (status) {
    SahhaSensorStatus.enabled => Colors.green.shade600,
    SahhaSensorStatus.disabled => Colors.orange.shade700,
    SahhaSensorStatus.unavailable => Colors.red.shade600,
    SahhaSensorStatus.pending => Colors.grey.shade600,
    null => Colors.grey.shade500,
  };
}

/// Small trailing/leading spinner used for per-row and per-section loading.
class _RowSpinner extends StatelessWidget {
  const _RowSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _LogEntry {
  const _LogEntry(this.time, this.message, this.isError);

  final String time;
  final String message;
  final bool isError;
}
