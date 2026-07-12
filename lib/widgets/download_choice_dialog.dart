import 'package:flutter/material.dart';
import 'package:ta3dia/l10n/app_localizations.dart';

enum ExportFormat { pdf, excel }

Future<ExportFormat?> showDownloadChoiceDialog(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  return showDialog<ExportFormat>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.localeName == 'ar' ? 'تنزيل' : 'Download', style: TextStyle(color: cs.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: cs.primary),
            title: Text('PDF', style: TextStyle(color: cs.onSurface)),
            onTap: () => Navigator.pop(ctx, ExportFormat.pdf),
          ),
          ListTile(
            leading: Icon(Icons.table_chart, color: cs.primary),
            title: Text('Excel', style: TextStyle(color: cs.onSurface)),
            onTap: () => Navigator.pop(ctx, ExportFormat.excel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ],
    ),
  );
}
