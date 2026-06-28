import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    if (!connectivity.isOffline) {
      if (_dismissed) {
        _dismissed = false;
      }
      return SizedBox.shrink();
    }

    if (_dismissed) return SizedBox.shrink();

    final pending = context.select((OfflineQueueService s) => s.pendingCount);
    final l = AppLocalizations.of(context)!;
    final isRtl = l.localeName == 'ar';
    final cs = Theme.of(context).colorScheme;

    final message = isRtl
        ? pending > 0
            ? 'في وضع عدم الاتصال. سيتم حفظ $pending عنصر محلياً ومزامنتها عند العودة للاتصال.'
            : 'في وضع عدم الاتصال. سيتم حفظ بياناتك محلياً ومزامنتها عند العودة للاتصال.'
        : pending > 0
            ? 'Offline. $pending item${pending > 1 ? 's' : ''} saved locally, will sync when online.'
            : 'Offline. Your data will be saved locally and synced when back online.';

    return MaterialBanner(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: cs.errorContainer,
      content: Row(
        children: [
          Icon(Icons.wifi_off, size: 20, color: cs.onErrorContainer),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _dismissed = true),
          child: Text(
            isRtl ? 'حسناً' : 'OK',
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      ],
    );
  }
}
