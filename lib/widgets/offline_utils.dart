import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/connectivity_service.dart';

/// Returns true if the user is offline and shows a blocking snackbar.
/// Call this at the start of any action that requires network.
bool guardOffline(BuildContext context) {
  final offline = context.read<ConnectivityService>().isOffline;
  if (!offline) return false;

  final l = AppLocalizations.of(context)!;
  final isRtl = l.localeName == 'ar';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isRtl
            ? 'لا يمكنك تنفيذ هذا الإجراء حالياً لعدم الاتصال بالإنترنت.'
            : 'You cannot do this action offline.',
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
  return true;
}
