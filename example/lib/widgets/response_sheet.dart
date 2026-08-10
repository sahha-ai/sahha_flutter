import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pretty prints [raw] when it contains valid JSON, otherwise returns the
/// original string unchanged.
String tryPrettyJson(String raw) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
  } catch (_) {
    return raw;
  }
}

/// Monospace style for JSON/API output.
TextStyle monoStyle(BuildContext context, {double fontSize = 12}) {
  return TextStyle(
    fontFamily: Platform.isIOS ? 'Menlo' : 'monospace',
    fontSize: fontSize,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

/// Shows an API response (or error) in a draggable bottom sheet with a
/// selectable monospace body and a copy button.
Future<void> showResponseSheet(
  BuildContext context, {
  required String title,
  required String body,
  String? subtitle,
  bool isError = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy to clipboard',
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: body));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SelectableText(body, style: monoStyle(context)),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
