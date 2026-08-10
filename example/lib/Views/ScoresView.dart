import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/date_range_selector.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _typesPrefsKey = 'scores.types';

const _defaultScoreTypes = <SahhaScoreType>{
  SahhaScoreType.activity,
  SahhaScoreType.sleep,
  SahhaScoreType.wellbeing,
};

/// Test harness for [SahhaFlutter.getScores]: pick score types and a date
/// range, then inspect the parsed response inline.
class ScoresView extends StatefulWidget {
  const ScoresView({super.key});

  @override
  State<ScoresView> createState() => ScoresState();
}

class ScoresState extends State<ScoresView> {
  static final DateFormat _dateTimeFormat = DateFormat('d MMM, HH:mm');

  final Set<SahhaScoreType> _types = {..._defaultScoreTypes};

  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();

  bool _isLoading = false;

  /// Raw response of the last successful call, `null` before the first one.
  String? _rawResponse;
  List<_ScoreEntry> _entries = const [];
  DateTime? _queriedStart;
  DateTime? _queriedEnd;

  @override
  void initState() {
    super.initState();

    _restoreSelections();
  }

  /// Selection in enum order so the request is stable regardless of the order
  /// the user tapped things in.
  List<SahhaScoreType> get _selectedTypes => [
    for (final type in SahhaScoreType.values)
      if (_types.contains(type)) type,
  ];

  Future<void> _restoreSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_typesPrefsKey);
    if (stored == null) return;
    final byName = {for (final type in SahhaScoreType.values) type.name: type};
    final restored = <SahhaScoreType>{
      for (final name in stored)
        if (byName[name] case final type?) type,
    };
    // Every stored name is unknown (renamed enum): keep the defaults.
    if (restored.isEmpty && stored.isNotEmpty) return;
    if (!mounted) return;
    setState(() {
      _types
        ..clear()
        ..addAll(restored);
    });
  }

  Future<void> _persistSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_typesPrefsKey, [
      for (final type in _selectedTypes) type.name,
    ]);
  }

  void _toggleType(SahhaScoreType type, bool selected) {
    setState(() {
      if (selected) {
        _types.add(type);
      } else {
        _types.remove(type);
      }
    });
    _persistSelections();
  }

  Future<void> _getScores() async {
    if (_types.isEmpty || _isLoading) return;

    final start = _start;
    final end = _end;
    setState(() => _isLoading = true);

    try {
      final raw = await SahhaFlutter.getScores(
        types: _selectedTypes,
        startDateTime: start,
        endDateTime: end,
      );
      debugPrint('GET SCORES: $raw');
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
      debugPrint('GET SCORES error: $error');
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
        title: 'GET SCORES',
        body: error.toString(),
        subtitle: 'Request failed — authenticate the profile and try again',
        isError: true,
      );
    }
  }

  List<_ScoreEntry> _parseEntries(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      debugPrint('GET SCORES: response was not JSON ($error)');
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) _ScoreEntry(item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scores')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _sectionHeader(theme, 'Score types'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final type in SahhaScoreType.values)
                FilterChip(
                  label: Text(_prettyLabel(type.name)),
                  selected: _types.contains(type),
                  onSelected: (selected) => _toggleType(type, selected),
                ),
            ],
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
          if (_types.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _InlineHint(
                message: 'Select at least one score type to run the request.',
              ),
            ),
          FilledButton(
            onPressed: _types.isNotEmpty && !_isLoading ? _getScores : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('GET SCORES'),
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
                title: 'GET SCORES',
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
        for (final entry in _entries)
          _ScoreCard(entry: entry, dateTimeFormat: _dateTimeFormat),
    ];
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.entry, required this.dateTimeFormat});

  final _ScoreEntry entry;
  final DateFormat dateTimeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = entry.state;
    final stateColor = _stateColor(theme, state);
    final fraction = entry.scoreFraction;
    final dateLabel = _formatDateTime(dateTimeFormat, entry.scoreDateTime);
    final factors = entry.factors;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prettyLabel(entry.type ?? 'Unknown type'),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (dateLabel != null)
                            Text(
                              dateLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state != null)
                      _StatusChip(
                        label: _prettyLabel(state),
                        color: stateColor,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (fraction == null)
                  Text(
                    'No score value in the response',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            color: stateColor,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _percentLabel(fraction),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (factors.isNotEmpty)
            ExpansionTile(
              // The card already draws the border and padding, so the tile
              // stays flush with it whatever the app theme sets.
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Factors (${factors.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              children: [
                for (final factor in factors) _FactorRow(factor: factor),
              ],
            ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final _ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = factor.state;
    final fraction = factor.scoreFraction;
    final unit = factor.unit;
    final value = factor.value;
    final goal = factor.goal;

    final details = <String>[
      if (value != null) unit == null ? value : '$value $unit',
      if (goal != null) 'goal ${unit == null ? goal : '$goal $unit'}',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prettyLabel(factor.name ?? 'Unknown factor'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state != null || fraction != null)
            _StatusChip(
              label: [
                if (state != null) _prettyLabel(state),
                if (fraction != null) _percentLabel(fraction),
              ].join(' · '),
              color: _stateColor(theme, state),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
              'No scores for this range',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Scores are generated from processed sensor data, so they can '
              'take a while to appear. Check that the profile is '
              'authenticated, that sensor permissions are granted, and try a '
              'wider date range.',
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

/// Shared key-normalising base for the `getScores` payload: keys are lower
/// cased with underscores stripped so the same getter works whether the
/// platform returns `scoreDateTime` or `score_date_time`, and every getter
/// tolerates a missing or unexpectedly typed field.
class _JsonRow {
  _JsonRow(Map<Object?, Object?> json)
    : _fields = {
        for (final entry in json.entries) _normaliseKey(entry.key): entry.value,
      };

  final Map<String, Object?> _fields;

  static String _normaliseKey(Object? key) =>
      key.toString().toLowerCase().replaceAll('_', '');

  Object? raw(String key) => _fields[_normaliseKey(key)];

  String? string(String key) {
    final value = raw(key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? number(String key) {
    final value = raw(key);
    if (value == null) return null;
    if (value is num) return _formatNumber(value);
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Score values are usually a 0–1 double, but a 0–100 percentage is handled
  /// too. Returns `null` when the field is missing or not a number.
  double? fraction(String key) {
    final value = raw(key);
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    final ratio = parsed > 1 ? parsed / 100 : parsed;
    return ratio.clamp(0.0, 1.0).toDouble();
  }
}

/// One item of the `getScores` response.
class _ScoreEntry extends _JsonRow {
  _ScoreEntry(super.json);

  String? get type => string('type') ?? string('scoreType');

  String? get state => string('state');

  double? get scoreFraction => fraction('score');

  Object? get scoreDateTime => raw('scoreDateTime') ?? raw('startDateTime');

  List<_ScoreFactor> get factors {
    final value = raw('factors');
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) _ScoreFactor(item),
    ];
  }
}

/// One item of a score's `factors` array.
class _ScoreFactor extends _JsonRow {
  _ScoreFactor(super.json);

  String? get name => string('name') ?? string('factor');

  String? get state => string('state');

  String? get value => number('value');

  String? get goal => number('goal');

  String? get unit => string('unit');

  double? get scoreFraction => fraction('score');
}

/// `mental_wellbeing` -> `Mental wellbeing`.
String _prettyLabel(String name) {
  final words = name.replaceAll('_', ' ').trim();
  if (words.isEmpty) return name;
  return words[0].toUpperCase() + words.substring(1);
}

String _percentLabel(double fraction) => '${(fraction * 100).round()}%';

/// Semantic colour for a score/factor state string.
Color _stateColor(ThemeData theme, String? state) {
  switch (state?.trim().toLowerCase()) {
    case 'high':
    case 'good':
    case 'optimal':
      return Colors.green.shade700;
    case 'medium':
    case 'ok':
    case 'moderate':
    case 'average':
      return Colors.orange.shade800;
    case 'low':
    case 'poor':
    case 'minimal':
      return Colors.red.shade700;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
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
