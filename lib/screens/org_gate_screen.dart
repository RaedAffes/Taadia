import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/screens/home_screen.dart';
import 'package:ta3dia/screens/create_organization_screen.dart';
import 'package:ta3dia/screens/join_organization_screen.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class OrgGateScreen extends StatefulWidget {
  @override
  State<OrgGateScreen> createState() => _OrgGateScreenState();
}

class _OrgGateScreenState extends State<OrgGateScreen> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOrgs());
  }

  Future<void> _checkOrgs() async {
    final auth = context.read<AuthService>();
    final orgService = context.read<OrgService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    await orgService.loadMyOrgs(uid);
    if (!mounted) return;

    if (orgService.myOrgs.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthService>();

    if (_checking) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.appName),
              content: Text(l.exitConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.exit, style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (exit == true) {
            await auth.signOut();
          }
        }
      },
      child: AppScaffold(
        title: l.joinOrCreateOrg,
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (auth.currentUser != null)
                Text(
                  auth.currentUser!.isAnonymous
                      ? l.welcome
                      : l.welcomeUser(
                          auth.currentUser!.displayName?.isNotEmpty == true
                              ? auth.currentUser!.displayName!
                              : (auth.currentUser!.email?.isNotEmpty == true
                                  ? auth.currentUser!.email!.split('@').first
                                  : ''),
                        ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              SizedBox(height: 8),
              Text(
                l.orgGateSubtitle,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              _card(
                context,
                icon: Icons.group_add,
                title: l.joinOrgCardTitle,
                subtitle: l.joinOrgCardDesc,
                color: cs.primary,
                l: l,
                onTap: () async {
                  analytics.logEvent(name: 'join_org_clicked');
                  final joined = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => JoinOrganizationScreen()),
                  );
                  if (joined == true && mounted) {
                    _checkOrgs();
                  }
                },
              ),
              SizedBox(height: 16),
              _card(
                context,
                icon: Icons.business,
                title: l.createOrgCardTitle,
                subtitle: l.createOrgCardDesc,
                color: cs.tertiary,
                l: l,
                onTap: () async {
                  analytics.logEvent(name: 'create_org_clicked');
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreateOrganizationScreen()),
                  );
                  if (created == true && mounted) {
                    _checkOrgs();
                  }
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          Icon(icon, color: Colors.white, size: 30),
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
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
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
