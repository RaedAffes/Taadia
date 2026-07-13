import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/screens/public_taadias_list_screen.dart';
import 'package:ta3dia/screens/private_taadias_list_screen.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class AdminManageTaadiaScreen extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final authService = Provider.of<AuthService>(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.appName),
              content: Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Exit', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (exit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: AppScaffold(
      title: l.manageTaadia,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authService.currentUser != null) Text(
              l.welcomeUser(
                authService.currentUser!.displayName?.isNotEmpty == true
                    ? authService.currentUser!.displayName!
                    : (authService.currentUser!.email?.isNotEmpty == true
                        ? authService.currentUser!.email!.split('@').first
                        : l.guest),
              ),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l.homeSubtitle,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _optionCard(
              context,
              icon: Icons.public,
              title: l.publicTaadias,
              subtitle: l.joinTaadiaDesc,
              color: cs.primary,
              onTap: () {
                analytics.logEvent(
                  name: 'navigate_to_admin_dashboard',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PublicTaadiasListScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            _optionCard(
              context,
              icon: Icons.lock_outline,
              title: l.myPrivateTaadias,
              subtitle: l.privateTaadiaNotice,
              color: cs.tertiary,
              onTap: () {
                analytics.logEvent(
                  name: 'navigate_to_private_taadias',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PrivateTaadiasListScreen()),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
