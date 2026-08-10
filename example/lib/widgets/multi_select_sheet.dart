import 'package:flutter/material.dart';

/// Generic searchable multi-select bottom sheet used for the long enum lists
/// (biomarker types, sensors, score types).
///
/// Returns the new selection when applied, or null when dismissed.
Future<Set<T>?> showMultiSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required Set<T> initialSelection,
  required String Function(T option) labelOf,
  String Function(T option)? groupOf,
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _MultiSelectSheet<T>(
        title: title,
        options: options,
        initialSelection: initialSelection,
        labelOf: labelOf,
        groupOf: groupOf,
        scrollController: scrollController,
      ),
    ),
  );
}

class _MultiSelectSheet<T> extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.labelOf,
    required this.groupOf,
    required this.scrollController,
  });

  final String title;
  final List<T> options;
  final Set<T> initialSelection;
  final String Function(T option) labelOf;
  final String Function(T option)? groupOf;
  final ScrollController scrollController;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late final Set<T> _selection = {...widget.initialSelection};
  String _query = '';

  List<T> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where((o) => widget.labelOf(o).toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    // Group the filtered options; map literals preserve insertion order, so
    // groups appear in first-seen order.
    final grouped = <String?, List<T>>{};
    for (final option in filtered) {
      grouped.putIfAbsent(widget.groupOf?.call(option), () => []).add(option);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: theme.textTheme.titleMedium),
                    Text(
                      '${_selection.length} of ${widget.options.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selection.addAll(filtered)),
                child: const Text('All'),
              ),
              TextButton(
                onPressed: () => setState(_selection.clear),
                child: const Text('None'),
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
          child: ListView(
            controller: widget.scrollController,
            children: [
              for (final entry in grouped.entries) ...[
                if (entry.key != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(
                      entry.key!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                for (final option in entry.value)
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(widget.labelOf(option)),
                    value: _selection.contains(option),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _selection.add(option);
                      } else {
                        _selection.remove(option);
                      }
                    }),
                  ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selection),
              child: const Text('Apply'),
            ),
          ),
        ),
      ],
    );
  }
}
