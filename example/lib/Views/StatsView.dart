import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/date_range_selector.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:sahha_flutter_example/widgets/sensor_groups.dart';
import 'package:sahha_flutter_example/widgets/sensor_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateFormat _dayFormat = DateFormat('EEE d MMM');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _dayTimeFormat = DateFormat('d MMM HH:mm');
final NumberFormat _numberFormat = NumberFormat.decimalPattern();

/// Test harness for the deprecated `getStats` API.
///
/// Kept so the aggregated on-device stats can be regression tested against the
/// server-processed values returned by `getBiomarkers`.
class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  StatsState createState() => StatsState();
}

class StatsState extends State<StatsView> {
  static const String _sensorPrefsKey = 'stats.sensor';

  SahhaSensor? _sensor = SahhaSensor.steps;
  late DateTime _start;
  late DateTime _end;
  bool _isLoading = false;
  String? _raw;
  String? _error;
  List<_Stat>? _stats;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(days: 7));

    _restoreSensor();
  }

  Future<void> _restoreSensor() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_sensorPrefsKey);
    if (name == null) return;
    // Tolerate sensors that were removed or renamed since the value was saved.
    final restored = _sensorNamed(name);
    if (restored == null || !mounted) return;
    setState(() => _sensor = restored);
  }

  Future<void> _saveSensor(SahhaSensor sensor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sensorPrefsKey, sensor.name);
  }

  SahhaSensor? _sensorNamed(String name) {
    for (final sensor in SahhaSensor.values) {
      if (sensor.name == name) return sensor;
    }
    return null;
  }

  Future<void> _pickSensor() async {
    final picked = await showSensorPicker(context, selected: _sensor);
    if (picked == null || !mounted) return;
    setState(() => _sensor = picked);
    await _saveSensor(picked);
  }

  Future<void> _getStats() async {
    final sensor = _sensor;
    if (sensor == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // The demo intentionally exercises the deprecated APIs alongside
      // getBiomarkers.
      // ignore: deprecated_member_use
      final raw = await SahhaFlutter.getStats(
        sensor: sensor,
        startDateTime: _start,
        endDateTime: _end,
      );
      debugPrint(raw);
      final stats = _parseStats(raw);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _raw = raw;
        _stats = stats;
      });
    } catch (error) {
      debugPrint(error.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _raw = null;
        _stats = null;
        _error = error.toString();
      });
      showResponseSheet(
        context,
        title: 'GET STATS',
        body: error.toString(),
        subtitle: sensor.name,
        isError: true,
      );
    }
  }

  void _showRawJson() {
    final raw = _raw;
    if (raw == null) return;
    final count = _stats?.length ?? 0;
    showResponseSheet(
      context,
      title: 'GET STATS',
      body: tryPrettyJson(raw),
      subtitle: '$count ${count == 1 ? 'entry' : 'entries'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensor = _sensor;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _DeprecationCallout(),
          const SizedBox(height: 20),
          const _SectionHeader('Query'),
          const SizedBox(height: 12),
          _SensorField(sensor: sensor, onTap: _isLoading ? null : _pickSensor),
          const SizedBox(height: 12),
          DateRangeSelector(
            start: _start,
            end: _end,
            onChanged: (start, end) => setState(() {
              _start = start;
              _end = end;
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading || sensor == null ? null : _getStats,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('GET STATS'),
            ),
          ),
          const SizedBox(height: 24),
          ..._results(theme),
        ],
      ),
    );
  }

  List<Widget> _results(ThemeData theme) {
    final error = _error;
    if (error != null) {
      return [
        _InfoCard(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
          title: 'GET STATS failed',
          message: error,
          action: TextButton(
            onPressed: () => showResponseSheet(
              context,
              title: 'GET STATS',
              body: error,
              subtitle: _sensor?.name,
              isError: true,
            ),
            child: const Text('Details'),
          ),
        ),
      ];
    }

    final stats = _stats;
    if (stats == null || _raw == null) return const [];

    return [
      Row(
        children: [
          Expanded(child: _resultsHeader(theme, stats)),
          TextButton(onPressed: _showRawJson, child: const Text('Raw JSON')),
        ],
      ),
      if (stats.isEmpty)
        _InfoCard(
          icon: Icons.inbox_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          title: 'No stats returned',
          message:
              'Nothing was recorded for ${_sensor?.name ?? 'this sensor'} in '
              'this date range. Check the sensor is enabled in Permissions and '
              'that the device has data for the period.',
        )
      else ...[
        const Divider(height: 1),
        for (final stat in stats) ...[
          _StatRow(stat: stat),
          const Divider(height: 1),
        ],
      ],
    ];
  }

  Widget _resultsHeader(ThemeData theme, List<_Stat> stats) {
    final values = [
      for (final stat in stats)
        if (stat.value != null) stat.value!,
    ];
    final details = <String>[];
    final types = {
      for (final stat in stats)
        if (stat.type != null) stat.type!,
    };
    if (types.isNotEmpty && types.length <= 3) {
      details.add(types.join(', '));
    }
    if (values.isNotEmpty) {
      final sum = values.fold<double>(0, (total, value) => total + value);
      details.add(
        'sum ${_numberFormat.format(sum)} · '
        'avg ${_numberFormat.format(sum / values.length)}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${stats.length} ${stats.length == 1 ? 'stat' : 'stats'}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (details.isNotEmpty)
          Text(
            details.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// A single `getStats` entry, parsed defensively: field names and value types
/// differ slightly between the iOS and Android bridges.
class _Stat {
  _Stat({
    required this.type,
    required this.value,
    required this.valueText,
    required this.unit,
    required this.start,
    required this.end,
    required this.rawStart,
    required this.sources,
  });

  final String? type;
  final double? value;
  final String? valueText;
  final String? unit;
  final DateTime? start;
  final DateTime? end;
  final String? rawStart;
  final List<String> sources;

  String get periodLabel {
    final start = this.start;
    if (start == null) return rawStart ?? 'Unknown period';
    final end = this.end;
    if (end == null) return _dayFormat.format(start);

    final minutes = end.difference(start).inMinutes;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    // Daily periodicity (or a zero-length period): the day alone is enough.
    final coversDay = minutes >= 23 * 60 && minutes <= 25 * 60;
    if (coversDay || minutes <= 0) return _dayFormat.format(start);
    if (sameDay) {
      return '${_dayFormat.format(start)} · '
          '${_timeFormat.format(start)}–${_timeFormat.format(end)}';
    }
    return '${_dayTimeFormat.format(start)} → ${_dayTimeFormat.format(end)}';
  }

  String get valueLabel {
    final value = this.value;
    final text = value != null
        ? _numberFormat.format(value)
        : (valueText ?? '—');
    final unit = this.unit;
    return unit == null || unit.isEmpty ? text : '$text $unit';
  }
}

List<_Stat> _parseStats(String raw) {
  final stats = <_Stat>[];
  for (final map in _decodeEntries(raw, const ['stats', 'data', 'items'])) {
    final value = _pick(map, const ['value', 'count', 'total']);
    final start = _asDateTime(
      _pick(map, const ['startDateTime', 'startDate', 'start']),
    );
    stats.add(
      _Stat(
        type: _asText(_pick(map, const ['type', 'name', 'sensor', 'category'])),
        value: _asDouble(value),
        valueText: _asText(value),
        unit: _asText(_pick(map, const ['unit', 'unitName'])),
        start: start,
        end: _asDateTime(_pick(map, const ['endDateTime', 'endDate', 'end'])),
        rawStart: _asText(
          _pick(map, const ['startDateTime', 'startDate', 'start']),
        ),
        sources: _asTextList(_pick(map, const ['sources', 'source'])),
      ),
    );
  }
  // Most recent period first.
  stats.sort((a, b) {
    final aStart = a.start;
    final bStart = b.start;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  });
  return stats;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.periodLabel, style: theme.textTheme.bodyMedium),
                if (stat.sources.isNotEmpty)
                  Text(
                    stat.sources.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            stat.valueLabel,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _SensorField extends StatelessWidget {
  const _SensorField({required this.sensor, required this.onTap});

  final SahhaSensor? sensor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensor = this.sensor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Sensor',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Icon(Icons.expand_more, size: 20),
        ),
        child: sensor == null
            ? Text(
                'Select a sensor',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sensor.name, style: theme.textTheme.bodyMedium),
                  Text(
                    sensorGroupOf(sensor),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DeprecationCallout extends StatelessWidget {
  const _DeprecationCallout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'getStats is deprecated',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'New integrations should use getBiomarkers. This screen '
                  'stays so the deprecated API can be regression tested.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/biomarkers'),
                    child: const Text('Open Biomarkers'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null)
                  Align(alignment: Alignment.centerLeft, child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decodes a bridge payload into a list of string-keyed maps, tolerating a
/// single object, a wrapper object and malformed JSON.
List<Map<String, dynamic>> _decodeEntries(
  String raw,
  List<String> wrapperKeys,
) {
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  if (decoded is Map) {
    for (final key in wrapperKeys) {
      final wrapped = decoded[key];
      if (wrapped is List) {
        decoded = wrapped;
        break;
      }
    }
  }
  if (decoded is Map) {
    return [decoded.map((key, value) => MapEntry(key.toString(), value))];
  }
  if (decoded is! List) return const [];
  return [
    for (final entry in decoded)
      if (entry is Map)
        entry.map((key, value) => MapEntry(key.toString(), value)),
  ];
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

String? _asText(dynamic value) {
  if (value == null || value is Iterable || value is Map) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

List<String> _asTextList(dynamic value) {
  if (value is Iterable) {
    return [
      for (final entry in value)
        if (_asText(entry) != null) _asText(entry)!,
    ];
  }
  final text = _asText(value);
  return text == null ? const [] : [text];
}

DateTime? _asDateTime(dynamic value) {
  if (value is num) {
    // Seconds or milliseconds since epoch, depending on the platform.
    final millis = value > 100000000000
        ? value.toInt()
        : (value * 1000).toInt();
    return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  }
  if (value is! String) return null;
  var text = value.trim();
  if (text.isEmpty) return null;
  // Android serialises ZonedDateTime with a trailing zone id, which
  // DateTime.parse rejects: 2026-05-21T09:00+12:00[Pacific/Auckland]
  final zoneIndex = text.indexOf('[');
  if (zoneIndex > 0) text = text.substring(0, zoneIndex);
  return DateTime.tryParse(text)?.toLocal();
}
