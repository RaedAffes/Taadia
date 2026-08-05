import 'package:flutter/material.dart';
import 'package:ta3dia/l10n/app_localizations.dart';

Future<bool?> showLeaveOrgDialog(
  BuildContext context, {
  required String orgName,
  required bool isOwner,
}) {
  final l = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isOwner ? Icons.shield_outlined : Icons.logout,
              color: isOwner ? cs.tertiary : cs.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(l.leaveOrgConfirm(orgName))),
          ],
        ),
        content: Text(
          isOwner ? l.ownerLeaveWarning : l.leaveOrgConsequence,
          style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.leave, style: TextStyle(color: isOwner ? cs.tertiary : cs.error)),
          ),
        ],
      );
    },
  );
}
