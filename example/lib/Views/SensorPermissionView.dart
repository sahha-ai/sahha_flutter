import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:sahha_flutter_example/widgets/sensor_groups.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises `getSensorStatus`, `enableSensors` and `openAppSettings` against
/// an arbitrary set of sensors picked on screen.
///
/// Both SDK calls run on exactly the checked list, which subsumes the fixed
/// "empty / some / all" buttons this screen used to carry: check nothing for
/// the empty-list edge case, check everything for the whole enum, or check any
/// subset in between. The selection is persisted so a device keeps whatever
/// the last test was.
class SensorPermissionView extends StatefulWidget {
  const SensorPermissionView({super.key});

  @override
  State<SensorPermissionView> createState() => SensorPermissionState();
}

class SensorPermissionState extends State<SensorPermissionView> {
  /// Checked sensors, persisted as enum-name strings.
  static const String _prefsKey = 'permissions.sensors';

  /// The pair the old "SOME" buttons hard-coded — now just a quick action.
  static const List<SahhaSensor> _defaultSensors = <SahhaSensor>[
    SahhaSensor.steps,
    SahhaSensor.sleep,
  ];

  static const String _getStatusCall = 'getSensorStatus';
  static const String _enableCall = 'enableSensors';

  static const int _maxLogEntries = 30;
  static final DateFormat _logTimeFormat = DateFormat('HH:mm:ss');

  /// Sensor groups in `sensorsGroupedInEnumOrder()` order, built once.
  static final List<_SensorGroup> _groups = _buildGroups();

  /// Every sensor flattened back out of [_groups], so a list handed to the SDK
  /// keeps each group contiguous.
  static final List<SahhaSensor> _ordered = <SahhaSensor>[
    for (final group in _groups) ...group.sensors,
  ];

  Set<SahhaSensor> _selected = _defaultSensors.toSet();

  /// Status returned by the most recent successful call.
  SahhaSensorStatus? _status;

  /// True when the most recent call threw, so the hero stops claiming a status.
  bool _lastCallFailed = false;

  /// Hero caption: "getSensorStatus · 3 sensors · 10:32:05".
  String? _caption;

  /// Name of the SDK call in flight, or null when idle.
  String? _busyCall;

  String? _settingsResult;

  final List<_LogEntry> _log = [];

  @override
  void initState() {
    super.initState();
    unawaited(_restoreThenCheck());
  }

  static List<_SensorGroup> _buildGroups() {
    final byGroup = <String, List<SahhaSensor>>{};
    for (final sensor in sensorsGroupedInEnumOrder()) {
      byGroup
          .putIfAbsent(sensorGroupOf(sensor), () => <SahhaSensor>[])
          .add(sensor);
    }
    return [
      for (final entry in byGroup.entries) _SensorGroup(entry.key, entry.value),
    ];
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

  // ------------------------------------------------------------ persistence

  Future<void> _restoreThenCheck() async {
    await _restoreSelection();
    if (!mounted) return;
    await _run(_getStatusCall, SahhaFlutter.getSensorStatus);
  }

  Future<void> _restoreSelection() async {
    List<String>? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getStringList(_prefsKey);
    } catch (error) {
      debugPrint('Permissions: reading $_prefsKey failed -> $error');
      _appendLog('Could not read the saved selection: $error', isError: true);
      return;
    }
    if (saved == null) {
      _appendLog(
        'No saved selection — using the default set '
        '(${_defaultSensors.map((sensor) => sensor.name).join(' + ')})',
      );
      return;
    }

    final byName = {
      for (final sensor in SahhaSensor.values) sensor.name: sensor,
    };
    final restored = <SahhaSensor>{};
    final unknown = <String>[];
    for (final name in saved) {
      final sensor = byName[name];
      if (sensor == null) {
        unknown.add(name);
      } else {
        restored.add(sensor);
      }
    }
    if (unknown.isNotEmpty) {
      _appendLog('Ignored unknown saved sensors: ${unknown.join(', ')}');
    }
    if (!mounted) return;
    setState(() => _selected = restored);
    _appendLog('Restored a saved selection of ${_countLabel(restored.length)}');
  }

  Future<void> _persistSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [
        for (final sensor in _checkedList()) sensor.name,
      ]);
    } catch (error) {
      debugPrint('Permissions: writing $_prefsKey failed -> $error');
      _appendLog('Could not save the selection: $error', isError: true);
    }
  }

  // -------------------------------------------------------------- selection

  /// The checked sensors in grouped-enum order — the exact list handed to the
  /// SDK by both actions.
  List<SahhaSensor> _checkedList() => [
    for (final sensor in _ordered)
      if (_selected.contains(sensor)) sensor,
  ];

  String _countLabel(int count) =>
      count == 0 ? 'empty list' : '$count sensor${count == 1 ? '' : 's'}';

  void _applySelection(Set<SahhaSensor> selection, String logMessage) {
    setState(() => _selected = selection);
    _appendLog(logMessage);
    unawaited(_persistSelection());
  }

  void _selectAll() => _applySelection(
    SahhaSensor.values.toSet(),
    'Selected all (${SahhaSensor.values.length})',
  );

  void _selectNone() => _applySelection(<SahhaSensor>{}, 'Selection cleared');

  void _selectDefault() => _applySelection(
    _defaultSensors.toSet(),
    'Selected the default set '
    '(${_defaultSensors.map((sensor) => sensor.name).join(' + ')})',
  );

  void _toggleSensor(SahhaSensor sensor, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(sensor);
      } else {
        _selected.remove(sensor);
      }
    });
    unawaited(_persistSelection());
  }

  void _toggleGroup(_SensorGroup group) {
    final selectWholeGroup = !group.sensors.every(_selected.contains);
    setState(() {
      if (selectWholeGroup) {
        _selected.addAll(group.sensors);
      } else {
        _selected.removeAll(group.sensors);
      }
    });
    _appendLog(
      selectWholeGroup
          ? 'Selected all of ${group.name} (${group.sensors.length})'
          : 'Cleared ${group.name} (${group.sensors.length})',
    );
    unawaited(_persistSelection());
  }

  // ---------------------------------------------------------------- actions

  void _getStatus() =>
      unawaited(_run(_getStatusCall, SahhaFlutter.getSensorStatus));

  void _enableSensors() =>
      unawaited(_run(_enableCall, SahhaFlutter.enableSensors));

  /// Runs [call] with the checked list. An empty list is deliberately allowed
  /// through: `enableSensors([])` is a guarded error, and seeing it fail
  /// without disturbing the stored set is the point of the E3 check.
  Future<void> _run(
    String name,
    Future<SahhaSensorStatus> Function(List<SahhaSensor>) call,
  ) async {
    if (_busyCall != null || !mounted) return;
    final sensors = _checkedList();
    final label = '$name · ${_countLabel(sensors.length)}';

    setState(() {
      _busyCall = name;
      _caption = '$label · running…';
    });
    _appendLog('$label requested');

    try {
      final status = await call(sensors);
      debugPrint(
        'Permissions: $name(${sensors.length} sensors) -> '
        '${status.name}',
      );
      if (!mounted) return;
      setState(() {
        _busyCall = null;
        _status = status;
        _lastCallFailed = false;
        _caption = '$label · ${_logTimeFormat.format(DateTime.now())}';
      });
      _appendLog('$label -> ${status.name}');
    } catch (error) {
      debugPrint(
        'Permissions: $name(${sensors.length} sensors) failed -> '
        '$error',
      );
      if (mounted) {
        setState(() {
          _busyCall = null;
          _status = null;
          _lastCallFailed = true;
          _caption =
              '$label · failed · '
              '${_logTimeFormat.format(DateTime.now())}';
        });
      }
      _appendLog('$label FAILED: $error', isError: true);
      if (!mounted) return;
      unawaited(
        showResponseSheet(
          context,
          title: '$name failed',
          subtitle: _countLabel(sensors.length),
          body: error.toString(),
          isError: true,
        ),
      );
    }
  }

  void _openAppSettings() {
    SahhaFlutter.openAppSettings();
    debugPrint('Permissions: openAppSettings() called');
    setState(
      () => _settingsResult = 'Opened ${_logTimeFormat.format(DateTime.now())}',
    );
    _appendLog('openAppSettings() called — check the OS permission screen');
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Permissions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusHero(
            status: _status,
            caption: _caption,
            failed: _lastCallFailed,
          ),
          _sectionHeader(theme, 'Sensors'),
          _buildSelectionCard(theme),
          const SizedBox(height: 12),
          for (final group in _groups) _buildGroupTile(theme, group),
          _sectionHeader(theme, 'Actions'),
          _buildActions(theme),
          _sectionHeader(theme, 'More'),
          _buildMoreCard(theme),
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

  Widget _buildSelectionCard(ThemeData theme) {
    final count = _selected.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count of ${SahhaSensor.values.length} sensors selected',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.done_all, size: 18),
                  label: const Text('All'),
                  onPressed: _selectAll,
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove_done, size: 18),
                  label: const Text('None'),
                  onPressed: _selectNone,
                ),
                ActionChip(
                  avatar: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Default'),
                  onPressed: _selectDefault,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Default = '
              '${_defaultSensors.map((sensor) => sensor.name).join(' + ')}. '
              'Expand a group below to check individual sensors.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTile(ThemeData theme, _SensorGroup group) {
    final selected = group.sensors.where(_selected.contains).length;
    final total = group.sensors.length;
    final bool? groupValue = selected == 0
        ? false
        : selected == total
        ? true
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: PageStorageKey<String>('permissions.group.${group.name}'),
        tilePadding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Checkbox(
          tristate: true,
          value: groupValue,
          onChanged: (_) => _toggleGroup(group),
        ),
        title: Text(
          group.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$selected/$total selected',
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected == 0
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
        ),
        children: [
          for (final sensor in group.sensors)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.only(left: 8, right: 16),
              value: _selected.contains(sensor),
              onChanged: (value) => _toggleSensor(sensor, value ?? false),
              title: Text(sensor.name, style: monoStyle(context, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    final busy = _busyCall != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonal(
          onPressed: busy ? null : _getStatus,
          child: _buttonChild(
            theme,
            'GET STATUS',
            Icons.fact_check_outlined,
            _busyCall == _getStatusCall,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : _enableSensors,
          child: _buttonChild(
            theme,
            'ENABLE SENSORS',
            Icons.lock_open_outlined,
            _busyCall == _enableCall,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Both calls run on exactly the checked list. ENABLE SENSORS is the '
          'one that triggers the OS permission prompt. An empty list is a '
          'guarded error — enableSensors([]) fails with "Sensor set cannot be '
          'empty." and leaves the stored set untouched.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buttonChild(ThemeData theme, String label, IconData icon, bool busy) {
    if (busy) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.onSurface,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }

  Widget _buildMoreCard(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            shape: const RoundedRectangleBorder(),
            leading: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Open app settings'),
            subtitle: Text(
              'openAppSettings() opens the OS permission screen for this app.',
              style: theme.textTheme.bodySmall,
            ),
            trailing: _settingsResult == null
                ? null
                : Text(
                    _settingsResult!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
            onTap: _openAppSettings,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            shape: const RoundedRectangleBorder(),
            leading: Icon(
              Icons.fact_check_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Per-sensor diagnostics'),
            subtitle: Text(
              'This screen returns one combined status. Diagnostics shows '
              'each sensor\'s individual status.',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () => Navigator.pushNamed(context, '/diagnostics'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _log.isEmpty
              ? [
                  Text(
                    'Nothing yet. Every call, result and selection change is '
                    'logged here, newest first.',
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

/// A named bucket of sensors, from `sensorGroupOf`.
class _SensorGroup {
  const _SensorGroup(this.name, this.sensors);

  final String name;
  final List<SahhaSensor> sensors;
}

class _LogEntry {
  const _LogEntry(this.time, this.message, this.isError);

  final String time;
  final String message;
  final bool isError;
}

/// Hero card for the combined [SahhaSensorStatus] of the most recent call.
class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.status,
    required this.caption,
    required this.failed,
  });

  final SahhaSensorStatus? status;
  final String? caption;
  final bool failed;

  Color get _color {
    if (failed) return Colors.red.shade700;
    return switch (status) {
      SahhaSensorStatus.enabled => Colors.green.shade600,
      SahhaSensorStatus.disabled => Colors.orange.shade800,
      SahhaSensorStatus.unavailable => Colors.red.shade600,
      SahhaSensorStatus.pending => Colors.grey.shade600,
      null => Colors.grey.shade500,
    };
  }

  IconData get _icon {
    if (failed) return Icons.error_outline;
    return switch (status) {
      SahhaSensorStatus.enabled => Icons.sensors,
      SahhaSensorStatus.disabled => Icons.sensors_off,
      SahhaSensorStatus.unavailable => Icons.do_not_disturb_on_outlined,
      SahhaSensorStatus.pending => Icons.hourglass_empty,
      null => Icons.help_outline,
    };
  }

  String get _label {
    if (failed) return 'call failed';
    return status?.name ?? 'not checked yet';
  }

  String get _description {
    if (failed) return 'The call threw — see the log entry for the error.';
    return switch (status) {
      SahhaSensorStatus.enabled =>
        'Collection is active for every sensor in the list.',
      SahhaSensorStatus.disabled =>
        'The user declined, or turned the requested sensors off.',
      SahhaSensorStatus.unavailable =>
        'Health data is not available on this device.',
      SahhaSensorStatus.pending =>
        'The user has not been asked for these sensors yet.',
      null => 'Run GET STATUS or ENABLE SENSORS on the checked list.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return Card(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Combined sensor status',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caption ?? 'No call made yet',
                    style: monoStyle(
                      context,
                      fontSize: 11,
                    ).copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
