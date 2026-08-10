import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/date_range_selector.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:sahha_flutter_example/widgets/sensor_groups.dart';
import 'package:sahha_flutter_example/widgets/sensor_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateFormat _dayHeaderFormat = DateFormat('EEEE d MMMM');
final DateFormat _timeFormat = DateFormat('HH:mm');
final NumberFormat _numberFormat = NumberFormat.decimalPattern();

/// Samples beyond this are only available through the raw payload: rendering
/// every row of a busy day (heart rate, steps) would stall the list.
const int _maxRenderedSamples = 300;

/// Test harness for the deprecated `getSamples` API.
///
/// Kept so the raw on-device samples can be regression tested against the
/// server-processed values returned by `getBiomarkers`.
class SamplesView extends StatefulWidget {
  const SamplesView({super.key});

  @override
  SamplesState createState() => SamplesState();
}

class SamplesState extends State<SamplesView> {
  static const String _sensorPrefsKey = 'samples.sensor';

  SahhaSensor? _sensor = SahhaSensor.steps;
  late DateTime _start;
  late DateTime _end;
  bool _isLoading = false;
  String? _raw;
  String? _error;
  List<_Sample>? _samples;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(hours: 24));

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

  Future<void> _getSamples() async {
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
      final raw = await SahhaFlutter.getSamples(
        sensor: sensor,
        startDateTime: _start,
        endDateTime: _end,
      );
      debugPrint(raw);
      final samples = _parseSamples(raw);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _raw = raw;
        _samples = samples;
      });
    } catch (error) {
      debugPrint(error.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _raw = null;
        _samples = null;
        _error = error.toString();
      });
      showResponseSheet(
        context,
        title: 'GET SAMPLES',
        body: error.toString(),
        subtitle: sensor.name,
        isError: true,
      );
    }
  }

  void _showRawJson() {
    final raw = _raw;
    if (raw == null) return;
    final count = _samples?.length ?? 0;
    showResponseSheet(
      context,
      title: 'GET SAMPLES',
      body: tryPrettyJson(raw),
      subtitle: '$count ${count == 1 ? 'entry' : 'entries'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensor = _sensor;

    return Scaffold(
      appBar: AppBar(title: const Text('Samples')),
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
              onPressed: _isLoading || sensor == null ? null : _getSamples,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('GET SAMPLES'),
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
          title: 'GET SAMPLES failed',
          message: error,
          action: TextButton(
            onPressed: () => showResponseSheet(
              context,
              title: 'GET SAMPLES',
              body: error,
              subtitle: _sensor?.name,
              isError: true,
            ),
            child: const Text('Details'),
          ),
        ),
      ];
    }

    final samples = _samples;
    if (samples == null || _raw == null) return const [];

    final shown = samples.length > _maxRenderedSamples
        ? samples.sublist(0, _maxRenderedSamples)
        : samples;

    // Group by calendar day, keeping the (already descending) sample order.
    final byDay = <String, List<_Sample>>{};
    for (final sample in shown) {
      final start = sample.start;
      final day = start == null
          ? 'Unknown date'
          : _dayHeaderFormat.format(start);
      byDay.putIfAbsent(day, () => []).add(sample);
    }

    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${samples.length} '
                  '${samples.length == 1 ? 'sample' : 'samples'}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (byDay.isNotEmpty)
                  Text(
                    '${byDay.length} ${byDay.length == 1 ? 'day' : 'days'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: _showRawJson, child: const Text('Raw JSON')),
        ],
      ),
      if (samples.isEmpty)
        _InfoCard(
          icon: Icons.inbox_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          title: 'No samples returned',
          message:
              'Nothing was recorded for ${_sensor?.name ?? 'this sensor'} in '
              'this date range. Check the sensor is enabled in Permissions and '
              'that the device has data for the period.',
        )
      else ...[
        for (final entry in byDay.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(
              entry.key,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Divider(height: 1),
          for (final sample in entry.value) ...[
            _SampleRow(sample: sample),
            const Divider(height: 1),
          ],
        ],
        if (shown.length < samples.length)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Showing ${shown.length} of ${samples.length} — open Raw JSON '
              'for the full payload',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    ];
  }
}

/// A single `getSamples` entry, parsed defensively: field names and value types
/// differ slightly between the iOS and Android bridges.
class _Sample {
  _Sample({
    required this.value,
    required this.valueText,
    required this.unit,
    required this.start,
    required this.end,
    required this.rawStart,
    required this.source,
    required this.recordingMethod,
    required this.statCount,
  });

  final double? value;
  final String? valueText;
  final String? unit;
  final DateTime? start;
  final DateTime? end;
  final String? rawStart;
  final String? source;
  final String? recordingMethod;
  final int statCount;

  String get timeLabel {
    final start = this.start;
    if (start == null) return rawStart ?? 'Unknown time';
    final end = this.end;
    if (end == null || end.isAtSameMomentAs(start)) {
      return _timeFormat.format(start);
    }
    return '${_timeFormat.format(start)}–${_timeFormat.format(end)}';
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

List<_Sample> _parseSamples(String raw) {
  final samples = <_Sample>[];
  for (final map in _decodeEntries(raw, const ['samples', 'data', 'items'])) {
    final value = _pick(map, const ['value', 'count']);
    final stats = map['stats'];
    samples.add(
      _Sample(
        value: _asDouble(value),
        valueText: _asText(value),
        unit: _asText(_pick(map, const ['unit', 'unitName'])),
        start: _asDateTime(
          _pick(map, const ['startDateTime', 'startDate', 'start']),
        ),
        end: _asDateTime(_pick(map, const ['endDateTime', 'endDate', 'end'])),
        rawStart: _asText(
          _pick(map, const ['startDateTime', 'startDate', 'start']),
        ),
        source: _asText(_pick(map, const ['source', 'sourceName', 'device'])),
        recordingMethod: _asText(
          _pick(map, const ['recordingMethod', 'recordingType']),
        ),
        statCount: stats is Iterable ? stats.length : 0,
      ),
    );
  }
  // Most recent sample first.
  samples.sort((a, b) {
    final aStart = a.start;
    final bStart = b.start;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  });
  return samples;
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.sample});

  final _Sample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <String>[
      if (sample.source != null) sample.source!,
      if (sample.recordingMethod != null) sample.recordingMethod!,
      if (sample.statCount > 0) '${sample.statCount} stats',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sample.timeLabel, style: theme.textTheme.bodyMedium),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chip in chips) _MetaChip(label: chip),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            sample.valueLabel,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
                  'getSamples is deprecated',
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
