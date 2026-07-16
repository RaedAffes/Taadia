import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/screens/private_taadias_list_screen.dart';
import 'package:ta3dia/screens/public_taadias_list_screen.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final authService = Provider.of<AuthService>(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analytics.logScreenView(screenName: 'home_screen');
    });
    
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
      title: l.startTaadia,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authService.currentUser != null) Text(
              authService.currentUser!.isAnonymous
                  ? l.welcome
                  : l.welcomeUser(
                      authService.currentUser!.displayName?.isNotEmpty == true
                          ? authService.currentUser!.displayName!
                          : (authService.currentUser!.email?.isNotEmpty == true
                              ? authService.currentUser!.email!.split('@').first
                              : ''),
                    ),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            if (!authService.isAdmin) ...[
              SizedBox(height: 8),
              Text(
                l.homeSubtitle,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 32),
            _card(
              context,
              icon: Icons.public,
              title: l.publicTaadias,
              subtitle: l.joinTaadiaDesc,
              color: cs.primary,
              l: l,
              onTap: () {
                analytics.logEvent(
                  name: 'public_taadias_clicked',
                  parameters: {
                    'user_id': authService.currentUser?.uid ?? '',
                  },
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PublicTaadiasListScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            _card(
              context,
              icon: Icons.lock_outline,
              title: l.myPrivateTaadias,
              subtitle: l.privateTaadiaNotice,
              color: cs.tertiary,
              l: l,
              onTap: () {
                analytics.logEvent(
                  name: 'private_taadias_clicked',
                  parameters: {
                    'user_id': authService.currentUser?.uid ?? '',
                  },
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

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required AppLocalizations l,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
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
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.startTaadia,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
