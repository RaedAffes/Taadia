import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class OfflineObserver extends StatefulWidget {
  final Widget child;

  const OfflineObserver({super.key, required this.child});

  @override
  State<OfflineObserver> createState() => _OfflineObserverState();
}

class _OfflineObserverState extends State<OfflineObserver> {
  ConnectivityService? _conn;
  bool _wasOnline = true;
  bool _showingDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conn?.removeListener(_onConnectivityChanged);
    _conn = Provider.of<ConnectivityService>(context);
    _wasOnline = _conn!.isOnline;
    _conn!.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    if (_conn == null) return;
    if (!_wasOnline && _conn!.isOnline) {
      _wasOnline = true;
      try {
        context.read<OfflineQueueService>().processQueue();
      } catch (_) {}
      return;
    }
    if (_wasOnline && _conn!.isOffline && !_showingDialog) {
      _wasOnline = false;
      _showingDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final l = AppLocalizations.of(ctx)!;
          final isRtl = l.localeName == 'ar';
          return AlertDialog(
            backgroundColor: Color(0xFFF5F0EB),
            icon: Icon(Icons.wifi_off, size: 48, color: Color(0xFF8B7D6B)),
            title: Text(
              isRtl ? 'أنت في وضع عدم الاتصال' : 'You are offline',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF3E3A36)),
            ),
            content: Text(
              isRtl
                  ? 'يمكنك مواصلة العمل على التطبيق بشكل طبيعي. سيتم حفظ بياناتك محلياً ومزامنتها تلقائياً عند عودة الاتصال.'
                  : 'You can continue using the app normally. Your data will be saved locally and synced automatically when the connection is restored.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF3E3A36)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _showingDialog = false;
                  Navigator.pop(ctx);
                },
                child: Text(
                  isRtl ? 'حسناً' : 'OK',
                  style: TextStyle(color: Color(0xFF8B7D6B)),
                ),
              ),
            ],
          );
        },
      ).then((_) => _showingDialog = false);
    }
  }

  @override
  void dispose() {
    _conn?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
