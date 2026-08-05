import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/models/organization_model.dart';
import 'package:ta3dia/screens/register_screen.dart';
import 'package:ta3dia/screens/settings_screen.dart';
import 'package:ta3dia/widgets/taadia_background.dart';
import 'package:ta3dia/widgets/islamic_header.dart';
import 'package:ta3dia/screens/my_organizations_screen.dart';
import 'package:ta3dia/screens/org_gate_screen.dart';
import 'package:ta3dia/screens/super_admin_orgs_dashboard.dart';
import 'package:ta3dia/widgets/offline_banner.dart';
import 'package:ta3dia/widgets/org/leave_org_dialog.dart';
import 'package:ta3dia/widgets/org/org_switcher_sheet.dart';


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
  final _scrollNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final orgService = Provider.of<OrgService>(context, listen: false);
        orgService.loadMyOrgs(uid).then((_) {
          _syncOrgToAllServices(context, orgService.currentOrg);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthService>(context);
    final isGuest = auth.appUser?.authProvider == 'anonymous';
    final isSuperAdmin = auth.isSuperAdmin;
    final hasOrg = Provider.of<OrgService>(context).currentOrg != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollNotifier,
          builder: (context, offset, _) {
            final rawProgress = (offset / 250).clamp(0.0, 1.0);
            final progress = Curves.easeOutCubic.transform(rawProgress);
            final headerHeight = 200.0 - progress * 136;

            return IslamicHeader(
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
              actions: [
                Builder(
                  builder: (ctx) {
                    final orgService = Provider.of<OrgService>(ctx);
                    final org = orgService.currentOrg;
                    if (org == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => _openOrgSwitcher(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                org.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textDirection: AppLocalizations.of(ctx)!.localeName == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (widget.actions != null) ...widget.actions!,
              ],
            );
          },
        ),
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
            // org removed from drawer
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
            if (isSuperAdmin)
              ListTile(
                leading: Icon(Icons.business_outlined, color: cs.primary),
                title: Text(
                  l.manageOrganizations,
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SuperAdminOrgsDashboard()),
                  );
                },
              ),
            if (hasOrg) ...[
              ListTile(
                leading: Icon(Icons.apps, color: cs.primary),
                title: Text(l.myOrganizations, style: TextStyle(color: cs.onSurface)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openMyOrganizations(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: cs.error),
                title: Text(l.leaveOrganization, style: TextStyle(color: cs.error)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _leaveCurrentOrg(context);
                },
              ),
            ],
            Spacer(),
            SizedBox(height: 16),
            _logoutTile(context, auth),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 45),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineBanner(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is ScrollEndNotification) {
                  final pos = notification.metrics.pixels;
                  _scrollNotifier.value = pos.clamp(0.0, 200.0);
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

  void _openOrgSwitcher(BuildContext ctx) {
    showOrgSwitcherSheet(
      ctx,
      onOrganizationsTap: () => _openMyOrganizations(ctx),
      onSelect: (org) => _switchOrg(ctx, org),
    );
  }

  void _switchOrg(BuildContext ctx, Organization org) {
    _syncOrgToAllServices(ctx, org);
    Provider.of<TaadiaService>(ctx, listen: false).loadTaadias();
    Provider.of<GroupService>(ctx, listen: false).loadGroups();
  }

  void _openMyOrganizations(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const MyOrganizationsScreen()),
    );
  }

  Future<void> _leaveCurrentOrg(BuildContext ctx) async {
    final orgService = Provider.of<OrgService>(ctx, listen: false);
    final auth = Provider.of<AuthService>(ctx, listen: false);
    final org = orgService.currentOrg;
    final uid = auth.currentUser?.uid;
    if (org == null || uid == null) return;

    final isOwner = org.createdBy == uid;
    final confirmed = await showLeaveOrgDialog(
      ctx,
      orgName: org.name,
      isOwner: isOwner,
    );
    if (confirmed != true || !ctx.mounted) return;

    final ok = await orgService.leaveOrganization(org.id, uid);
    if (!ctx.mounted) return;

    if (!ok && orgService.errorMessage == 'owner_cannot_leave') {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(ctx)!.ownerLeaveWarning),
          backgroundColor: Theme.of(ctx).colorScheme.error,
        ),
      );
      return;
    }

    _syncOrgToAllServices(ctx, orgService.currentOrg);
    if (orgService.myOrgs.isEmpty) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrgGateScreen()),
        (route) => false,
      );
    }
  }

  void _syncOrgToAllServices(BuildContext context, Organization? org) {
    final orgService = Provider.of<OrgService>(context, listen: false);
    final taadiaService = Provider.of<TaadiaService>(context, listen: false);
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    final groupService = Provider.of<GroupService>(context, listen: false);

    orgService.setCurrentOrg(org);

    final orgId = org?.id;
    taadiaService.setCurrentOrg(orgId);
    evalService.setCurrentOrg(orgId);
    groupService.setCurrentOrg(orgId);
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  await auth.signOut();
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
