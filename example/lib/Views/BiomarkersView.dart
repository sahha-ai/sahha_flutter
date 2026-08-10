import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/date_range_selector.dart';
import 'package:sahha_flutter_example/widgets/multi_select_sheet.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _categoriesPrefsKey = 'biomarkers.categories';
const _typesPrefsKey = 'biomarkers.types';

/// Test harness for [SahhaFlutter.getBiomarkers]: pick categories, types and a
/// date range, then inspect the parsed response inline.
class BiomarkersView extends StatefulWidget {
  const BiomarkersView({super.key});

  @override
  State<BiomarkersView> createState() => BiomarkersState();
}

class BiomarkersState extends State<BiomarkersView> {
  static final DateFormat _dateTimeFormat = DateFormat('d MMM, HH:mm');

  final Set<SahhaBiomarkerCategory> _categories = {
    ...SahhaBiomarkerCategory.values,
  };
  final Set<SahhaBiomarkerType> _types = {...SahhaBiomarkerType.values};

  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();

  bool _isLoading = false;

  /// Raw response of the last successful call, `null` before the first one.
  String? _rawResponse;
  List<_BiomarkerEntry> _entries = const [];
  DateTime? _queriedStart;
  DateTime? _queriedEnd;

  @override
  void initState() {
    super.initState();

    _restoreSelections();
  }

  bool get _hasSelection => _categories.isNotEmpty && _types.isNotEmpty;

  /// Selections in enum order so the request is stable regardless of the order
  /// the user tapped things in.
  List<SahhaBiomarkerCategory> get _selectedCategories => [
    for (final category in SahhaBiomarkerCategory.values)
      if (_categories.contains(category)) category,
  ];

  List<SahhaBiomarkerType> get _selectedTypes => [
    for (final type in SahhaBiomarkerType.values)
      if (_types.contains(type)) type,
  ];

  Future<void> _restoreSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final categories = _restore(
      prefs.getStringList(_categoriesPrefsKey),
      SahhaBiomarkerCategory.values,
    );
    final types = _restore(
      prefs.getStringList(_typesPrefsKey),
      SahhaBiomarkerType.values,
    );
    if (!mounted) return;
    setState(() {
      if (categories != null) {
        _categories
          ..clear()
          ..addAll(categories);
      }
      if (types != null) {
        _types
          ..clear()
          ..addAll(types);
      }
    });
  }

  /// Maps stored enum names back to values, silently dropping names that no
  /// longer exist. Returns `null` (keep the defaults) when nothing was stored
  /// or when every stored name is unknown.
  Set<T>? _restore<T extends Enum>(List<String>? stored, List<T> values) {
    if (stored == null) return null;
    final byName = {for (final value in values) value.name: value};
    final restored = <T>{
      for (final name in stored)
        if (byName[name] case final value?) value,
    };
    if (restored.isEmpty && stored.isNotEmpty) return null;
    return restored;
  }

  Future<void> _persistSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesPrefsKey, [
      for (final category in _selectedCategories) category.name,
    ]);
    await prefs.setStringList(_typesPrefsKey, [
      for (final type in _selectedTypes) type.name,
    ]);
  }

  void _toggleCategory(SahhaBiomarkerCategory category, bool selected) {
    setState(() {
      if (selected) {
        _categories.add(category);
      } else {
        _categories.remove(category);
      }
    });
    _persistSelections();
  }

  Future<void> _pickTypes() async {
    final selection = await showMultiSelectSheet<SahhaBiomarkerType>(
      context: context,
      title: 'Biomarker types',
      options: _typesGroupedInEnumOrder(),
      initialSelection: _types,
      labelOf: (type) => type.name,
      groupOf: _biomarkerGroupOf,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _types
        ..clear()
        ..addAll(selection);
    });
    await _persistSelections();
  }

  Future<void> _getBiomarkers() async {
    if (!_hasSelection || _isLoading) return;

    final start = _start;
    final end = _end;
    setState(() => _isLoading = true);

    try {
      final raw = await SahhaFlutter.getBiomarkers(
        categories: _selectedCategories,
        types: _selectedTypes,
        startDateTime: start,
        endDateTime: end,
      );
      debugPrint('GET BIOMARKERS: $raw');
      final entries = _parseEntries(raw);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _rawResponse = raw;
        _entries = entries;
        _queriedStart = start;
        _queriedEnd = end;
      });
    } catch (error) {
      debugPrint('GET BIOMARKERS error: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _rawResponse = null;
        _entries = const [];
        _queriedStart = null;
        _queriedEnd = null;
      });
      await showResponseSheet(
        context,
        title: 'GET BIOMARKERS',
        body: error.toString(),
        subtitle: 'Request failed — authenticate the profile and try again',
        isError: true,
      );
    }
  }

  List<_BiomarkerEntry> _parseEntries(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      debugPrint('GET BIOMARKERS: response was not JSON ($error)');
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) _BiomarkerEntry(item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTypes = SahhaBiomarkerType.values.length;
    final typesSummary = _types.length == totalTypes
        ? 'All types ($totalTypes)'
        : '${_types.length} of $totalTypes selected';

    return Scaffold(
      appBar: AppBar(title: const Text('Biomarkers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _sectionHeader(theme, 'Categories'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final category in SahhaBiomarkerCategory.values)
                FilterChip(
                  label: Text(_prettyLabel(category.name)),
                  selected: _categories.contains(category),
                  onSelected: (selected) => _toggleCategory(category, selected),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Types'),
          InkWell(
            onTap: _pickTypes,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Biomarker types',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: Icon(Icons.tune, size: 18),
              ),
              child: Text(typesSummary, style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Date range'),
          DateRangeSelector(
            start: _start,
            end: _end,
            onChanged: (start, end) => setState(() {
              _start = start;
              _end = end;
            }),
          ),
          const SizedBox(height: 24),
          if (!_hasSelection)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InlineHint(
                message: _categories.isEmpty
                    ? 'Select at least one category to run the request.'
                    : 'Select at least one biomarker type to run the request.',
              ),
            ),
          FilledButton(
            onPressed: _hasSelection && !_isLoading ? _getBiomarkers : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('GET BIOMARKERS'),
          ),
          ..._buildResults(theme),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  List<Widget> _buildResults(ThemeData theme) {
    final raw = _rawResponse;
    if (raw == null) return const [];

    final start = _queriedStart;
    final end = _queriedEnd;
    final range = start != null && end != null
        ? '${_dateTimeFormat.format(start)} – ${_dateTimeFormat.format(end)}'
        : null;

    // Insertion ordered, so types appear in the order the API returned them.
    final grouped = <String, List<_BiomarkerEntry>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.type ?? 'Unknown type', () => []).add(entry);
    }

    return [
      const SizedBox(height: 28),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _entries.length == 1
                        ? '1 result'
                        : '${_entries.length} results',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (range != null)
                    Text(
                      range,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showResponseSheet(
                context,
                title: 'GET BIOMARKERS',
                body: tryPrettyJson(raw),
                subtitle: '${_entries.length} results',
              ),
              child: const Text('Raw JSON'),
            ),
          ],
        ),
      ),
      if (_entries.isEmpty)
        const _EmptyResults()
      else
        for (final group in grouped.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              // The card already draws the border and padding, so the tile
              // stays flush with it whatever the app theme sets.
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              initiallyExpanded: grouped.length == 1,
              title: Text(
                _prettyLabel(group.key),
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                group.value.length == 1
                    ? '1 entry'
                    : '${group.value.length} entries',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                for (final entry in group.value)
                  _BiomarkerRow(entry: entry, dateTimeFormat: _dateTimeFormat),
              ],
            ),
          ),
    ];
  }
}

class _BiomarkerRow extends StatelessWidget {
  const _BiomarkerRow({required this.entry, required this.dateTimeFormat});

  final _BiomarkerEntry entry;
  final DateFormat dateTimeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = entry.unit;
    final value = entry.value ?? '—';
    final chips = <String>[
      if (entry.periodicity case final periodicity?) periodicity,
      if (entry.aggregation case final aggregation?) aggregation,
      if (entry.category case final category?) category,
    ];
    final period = _period(
      dateTimeFormat,
      entry.startDateTime,
      entry.endDateTime,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unit == null || unit.isEmpty ? value : '$value $unit',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [for (final chip in chips) _MiniChip(label: chip)],
              ),
            ),
          if (period != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                period,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String? _period(DateFormat format, Object? start, Object? end) {
    final startLabel = _formatDateTime(format, start);
    final endLabel = _formatDateTime(format, end);
    if (startLabel == null && endLabel == null) return null;
    if (startLabel == null) return 'until $endLabel';
    if (endLabel == null) return 'from $startLabel';
    return '$startLabel – $endLabel';
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

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

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No biomarkers for this range',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Sensor data can take a while to process after it is collected. '
              'Check that the profile is authenticated, that the sensors for '
              'these types are enabled, and try a wider date range.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// One item of the `getBiomarkers` response.
///
/// Keys are normalised (lower cased, underscores stripped) so the same getter
/// works whether the platform returns `startDateTime` or `start_date_time`, and
/// every getter tolerates a missing or unexpectedly typed field.
class _BiomarkerEntry {
  _BiomarkerEntry(Map<Object?, Object?> json)
    : _fields = {
        for (final entry in json.entries) _normaliseKey(entry.key): entry.value,
      };

  final Map<String, Object?> _fields;

  static String _normaliseKey(Object? key) =>
      key.toString().toLowerCase().replaceAll('_', '');

  Object? _raw(String key) => _fields[_normaliseKey(key)];

  String? _string(String key) {
    final raw = _raw(key);
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? get category => _string('category');

  String? get type =>
      _string('type') ?? _string('biomarkerType') ?? _string('name');

  String? get value {
    final raw = _raw('value');
    if (raw == null) return null;
    if (raw is num) return _formatNumber(raw);
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? get unit => _string('unit');

  String? get periodicity => _string('periodicity');

  String? get aggregation => _string('aggregation');

  Object? get startDateTime => _raw('startDateTime') ?? _raw('startDate');

  Object? get endDateTime => _raw('endDateTime') ?? _raw('endDate');
}

/// Buckets [SahhaBiomarkerType] into readable groups for the picker. Every
/// value of the enum currently maps to one of the five named groups; `Other`
/// is a safety net for values added to the plugin later.
String _biomarkerGroupOf(SahhaBiomarkerType type) {
  final name = type.name;
  bool startsWithAny(List<String> prefixes) =>
      prefixes.any((prefix) => name.startsWith(prefix));

  // Order matters: the vitals check runs before the body check so that
  // `body_temperature_basal` stays with the other temperatures, and the sleep
  // check only matches the `sleep_` prefix so that `heart_rate_sleep` and
  // friends stay in vitals.
  if (name.startsWith('sleep_')) return 'Sleep';
  if (startsWithAny(const [
    'heart_',
    'respiratory',
    'oxygen',
    'blood_',
    'vo2',
    'body_temperature',
    'skin_temperature',
  ])) {
    return 'Vitals';
  }
  if (startsWithAny(const [
    'steps',
    'floors_climbed',
    'active_',
    'activity_',
    'total_energy_burned',
  ])) {
    return 'Activity';
  }
  if (startsWithAny(const [
    'height',
    'weight',
    'body_',
    'fat_mass',
    'lean_mass',
    'waist_circumference',
    'resting_energy_burned',
  ])) {
    return 'Body';
  }
  if (startsWithAny(const ['age', 'biological_sex', 'date_of_birth'])) {
    return 'Demographic';
  }
  return 'Other';
}

/// Types in enum order, sorted so each group is contiguous even if a future
/// enum addition breaks the current ordering.
List<SahhaBiomarkerType> _typesGroupedInEnumOrder() {
  final byGroup = <String, List<SahhaBiomarkerType>>{};
  for (final type in SahhaBiomarkerType.values) {
    byGroup.putIfAbsent(_biomarkerGroupOf(type), () => []).add(type);
  }
  return [for (final group in byGroup.values) ...group];
}

/// `sleep_rem_duration` -> `Sleep rem duration`.
String _prettyLabel(String name) {
  final words = name.replaceAll('_', ' ').trim();
  if (words.isEmpty) return name;
  return words[0].toUpperCase() + words.substring(1);
}

String _formatNumber(num value) {
  if (value.isNaN || value.isInfinite) return value.toString();
  if (value is int || value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

/// Formats an ISO 8601 string or epoch milliseconds, falling back to the raw
/// value when it is neither.
String? _formatDateTime(DateFormat format, Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    return format.format(
      DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true).toLocal(),
    );
  }
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  return parsed == null ? text : format.format(parsed.toLocal());
}
