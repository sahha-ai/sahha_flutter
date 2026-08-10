import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Quick presets shown above the start/end tiles.
enum DateRangePreset {
  today('Today'),
  yesterday('Yesterday'),
  last24Hours('Last 24h'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days');

  const DateRangePreset(this.label);

  final String label;

  (DateTime, DateTime) resolve(DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DateRangePreset.today:
        return (startOfToday, now);
      case DateRangePreset.yesterday:
        return (startOfToday.subtract(const Duration(days: 1)), startOfToday);
      case DateRangePreset.last24Hours:
        return (now.subtract(const Duration(hours: 24)), now);
      case DateRangePreset.last7Days:
        return (now.subtract(const Duration(days: 7)), now);
      case DateRangePreset.last30Days:
        return (now.subtract(const Duration(days: 30)), now);
    }
  }
}

/// Shared start/end date-time controls for the query screens (Scores,
/// Biomarkers, Stats, Samples): preset chips plus tappable tiles that open
/// date and time pickers.
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTime start, DateTime end) onChanged;

  static final DateFormat _dateTimeFormat = DateFormat('d MMM, HH:mm');

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final current = isStart ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    if (isStart) {
      onChanged(picked, picked.isAfter(end) ? picked : end);
    } else {
      onChanged(picked.isBefore(start) ? picked : start, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final preset in DateRangePreset.values)
              ActionChip(
                label: Text(preset.label),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final (newStart, newEnd) = preset.resolve(DateTime.now());
                  onChanged(newStart, newEnd);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateTimeTile(
                label: 'Start',
                value: _dateTimeFormat.format(start),
                onTap: () => _pick(context, isStart: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateTimeTile(
                label: 'End',
                value: _dateTimeFormat.format(end),
                onTap: () => _pick(context, isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
