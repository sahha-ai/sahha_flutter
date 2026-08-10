import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/sensor_groups.dart';

/// Searchable single-select bottom sheet over every [SahhaSensor].
///
/// Sensors are listed in [sensorsGroupedInEnumOrder] order with a header per
/// [sensorGroupOf] group. Tapping a sensor pops the sheet and returns it;
/// dismissing the sheet returns null.
Future<SahhaSensor?> showSensorPicker(
  BuildContext context, {
  SahhaSensor? selected,
}) {
  return showModalBottomSheet<SahhaSensor>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _SensorPickerSheet(
        selected: selected,
        scrollController: scrollController,
      ),
    ),
  );
}

class _SensorPickerSheet extends StatefulWidget {
  const _SensorPickerSheet({
    required this.selected,
    required this.scrollController,
  });

  final SahhaSensor? selected;
  final ScrollController scrollController;

  @override
  State<_SensorPickerSheet> createState() => _SensorPickerSheetState();
}

class _SensorPickerSheetState extends State<_SensorPickerSheet> {
  static final List<SahhaSensor> _options = sensorsGroupedInEnumOrder();

  String _query = '';

  List<SahhaSensor> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _options;
    return _options
        .where(
          (sensor) =>
              sensor.name.toLowerCase().contains(query) ||
              sensorGroupOf(sensor).toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    // Group the filtered sensors, preserving first-seen group order.
    final grouped = <String, List<SahhaSensor>>{};
    for (final sensor in filtered) {
      grouped.putIfAbsent(sensorGroupOf(sensor), () => []).add(sensor);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sensor', style: theme.textTheme.titleMedium),
              Text(
                '${filtered.length} of ${_options.length} sensors',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No sensors match "${_query.trim()}"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView(
                  controller: widget.scrollController,
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          entry.key,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final sensor in entry.value)
                        _SensorTile(
                          sensor: sensor,
                          isSelected: sensor == widget.selected,
                        ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.sensor, required this.isSelected});

  final SahhaSensor sensor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      title: Text(sensor.name),
      trailing: isSelected
          ? Icon(Icons.check, size: 20, color: theme.colorScheme.primary)
          : null,
      onTap: () => Navigator.of(context).pop(sensor),
    );
  }
}
