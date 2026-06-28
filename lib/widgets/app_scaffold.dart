import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/providers/app_state.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/screens/register_screen.dart';
import 'package:ta3dia/screens/settings_screen.dart';
import 'package:ta3dia/screens/admin_manage_users.dart';
import 'package:ta3dia/screens/user_dashboard.dart';
import 'package:ta3dia/services/pwa_install.dart';
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

class AppScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthService>(context);
    final isGuest = auth.appUser?.authProvider == 'anonymous';
    final isAdmin = auth.isAdmin;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: IslamicHeader(
        title: title ?? '',
        subtitle: subtitle,
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
                  Scaffold.of(ctx).openDrawer();
                } else {
                  Navigator.of(ctx).pop();
                }
              },
            );
          },
        ),
        actions: [
          Consumer<AppState>(
            builder: (context, state, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: state.toggleTheme,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          key: ValueKey(state.isDark),
                          state.isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      state.setLanguage(
                        state.locale.languageCode == 'en' ? 'ar' : 'en',
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Text(
                          key: ValueKey(state.locale.languageCode),
                          state.locale.languageCode == 'en' ? 'AR' : 'EN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
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
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.dashboard, color: cs.onSurface),
                title: Text(
                  l.manageTaadia,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminManageTaadiaScreen(),
                    ),
                  );
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
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/images/app logo.png'),
              ),
              title: Text(l.installApp, style: TextStyle(color: cs.onSurface)),
              onTap: () async {
                Navigator.pop(context);
                final result = await triggerPwaInstall();
                if (result == 'already_installed' && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.installAppAlready),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (result == 'ios_instructions' && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.ios_share,
                                size: 32,
                                color: cs.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              l.installApp,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l.installAppIOS,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l.close,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if ((result == 'not_available' ||
                        result == 'dismissed') &&
                    context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.download_rounded, size: 24),
                          SizedBox(width: 10),
                          Text(l.installApp),
                        ],
                      ),
                      content: Text(l.installAppGeneric),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.close),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            _logoutTile(context, auth),
            SizedBox(height: 16),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineBanner(),
          Expanded(child: TaadiaBackground(child: body)),
        ],
      ),
      floatingActionButton: floatingActionButton,
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
