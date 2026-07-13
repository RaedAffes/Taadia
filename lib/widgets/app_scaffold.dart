import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/screens/register_screen.dart';
import 'package:ta3dia/screens/settings_screen.dart';
import 'package:ta3dia/screens/admin_manage_users.dart';
import 'package:ta3dia/screens/user_dashboard.dart';
import 'package:ta3dia/widgets/taadia_background.dart';
import 'package:ta3dia/widgets/islamic_header.dart';
import 'package:ta3dia/services/feedback_service.dart';
import 'package:ta3dia/screens/admin_feedback_screen.dart';
import 'package:ta3dia/screens/user_feedback_screen.dart';
import 'package:ta3dia/screens/private_taadias_list_screen.dart';
import 'package:ta3dia/screens/home_screen.dart';
import 'package:ta3dia/screens/admin_manage_taadia_screen.dart';
import 'package:ta3dia/screens/manage_groups_screen.dart';
import 'package:ta3dia/widgets/offline_banner.dart';


class AppScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  double _scrollOffset = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthService>(context);
    final isGuest = auth.appUser?.authProvider == 'anonymous';
    final isAdmin = auth.isAdmin;
    final cs = Theme.of(context).colorScheme;

    final rawProgress = (_scrollOffset / 250).clamp(0.0, 1.0);
    final progress = Curves.easeOutCubic.transform(rawProgress);
    final headerHeight = 200.0 - progress * 136;

    return Scaffold(
      appBar: IslamicHeader(
        key: ValueKey(headerHeight.round()),
        title: widget.title ?? '',
        subtitle: widget.subtitle,
        height: headerHeight,
        leading: Builder(
          builder: (ctx) {
            final isFirst = ModalRoute.of(ctx)?.isFirst ?? true;
            return IconButton(
              icon: Icon(
                isFirst ? Icons.menu : Icons.arrow_back,
                color: Colors.white,
              ),
              tooltip: isFirst ? null : l.goBack,
              onPressed: () {
                if (isFirst) {
                  Scaffold.of(ctx).openEndDrawer();
                } else {
                  Navigator.of(ctx).pop();
                }
              },
            );
          },
        ),
        actions: widget.actions,
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.3),
                    cs.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(
                        'assets/images/app logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.task_alt,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: cs.onSurface),
              title: Text(l.settings, style: TextStyle(color: cs.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                );
              },
            ),
            if (!isAdmin)
              ListTile(
                leading: Icon(Icons.rocket_launch, color: cs.onSurface),
                title: Text(l.startTaadia, style: TextStyle(color: cs.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            if (isAdmin) ...[
              ListTile(
                leading: Icon(Icons.people, color: cs.onSurface),
                title: Text(
                  l.manageUsers,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageUsersScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.group_work, color: cs.onSurface),
                title: Text(
                  l.manageGroups,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ManageGroupsScreen()),
                  );
                },
              ),
            ],
            if (isGuest)
              ListTile(
                leading: Icon(Icons.person_add, color: cs.onSurface),
                title: Text(l.signUp, style: TextStyle(color: cs.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
              ),
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.feedback, color: cs.onSurface),
                title: Text(
                  l.viewFeedback,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminFeedbackScreen()),
                  );
                },
              ),
            if (!isAdmin)
              ListTile(
                leading: Icon(Icons.feedback, color: cs.onSurface),
                title: Text(
                  l.giveFeedback,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserFeedbackScreen()),
                  );
                },
              ),
            Spacer(),
            _logoutTile(context, auth),
            SizedBox(height: 16),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineBanner(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  setState(() => _scrollOffset = notification.metrics.pixels);
                }
                return false;
              },
              child: TaadiaBackground(child: widget.body),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _logoutTile(BuildContext context, AuthService auth) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.logout, color: cs.error),
      title: Text(l.logout, style: TextStyle(color: cs.error)),
      onTap: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.logout),
            content: Text(l.areYouSure),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  auth.signOut();
                },
                child: Text(l.logout, style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        );
      },
    );
  }
}
