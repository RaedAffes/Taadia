import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/organization_model.dart';
import 'package:ta3dia/screens/create_organization_screen.dart';
import 'package:ta3dia/screens/join_organization_screen.dart';
import 'package:ta3dia/screens/manage_org_screen.dart';
import 'package:ta3dia/screens/org_gate_screen.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/org/leave_org_dialog.dart';
import 'package:ta3dia/widgets/org/org_card.dart';

class MyOrganizationsScreen extends StatefulWidget {
  const MyOrganizationsScreen({super.key});

  @override
  State<MyOrganizationsScreen> createState() => _MyOrganizationsScreenState();
}

class _MyOrganizationsScreenState extends State<MyOrganizationsScreen> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Map<String, String> _roles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analytics.logScreenView(screenName: 'my_organizations');
      _loadRoles();
    });
  }

  Future<void> _loadRoles() async {
    final orgService = Provider.of<OrgService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final roles = <String, String>{};
    for (final org in orgService.myOrgs) {
      final role = await orgService.getMemberRole(org.id, uid);
      roles[org.id] = role ?? 'user';
    }
    if (mounted) setState(() => _roles.addAll(roles));
  }

  void _switchOrg(Organization org) {
    final ctx = context;
    final orgService = Provider.of<OrgService>(ctx, listen: false);
    final orgId = org.id;
    orgService.setCurrentOrg(org);
    Provider.of<TaadiaService>(ctx, listen: false).setCurrentOrg(orgId);
    Provider.of<EvaluationService>(ctx, listen: false).setCurrentOrg(orgId);
    Provider.of<GroupService>(ctx, listen: false).setCurrentOrg(orgId);
    Provider.of<TaadiaService>(ctx, listen: false).loadTaadias();
    Provider.of<GroupService>(ctx, listen: false).loadGroups();
    if (mounted) setState(() {});
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(ctx)!.currentOrg} · ${org.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _leaveOrg(Organization org) async {
    final l = AppLocalizations.of(context)!;
    final orgService = Provider.of<OrgService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showLeaveOrgDialog(
      context,
      orgName: org.name,
      isOwner: org.createdBy == uid,
    );
    if (confirmed != true || !mounted) return;

    final ok = await orgService.leaveOrganization(org.id, uid);
    if (!mounted) return;

    if (!ok && orgService.errorMessage == 'owner_cannot_leave') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.ownerLeaveWarning),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _roles.remove(org.id);
    setState(() {});
    if (orgService.myOrgs.isEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrgGateScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _openJoin() async {
    analytics.logEvent(name: 'join_org_clicked');
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JoinOrganizationScreen()),
    );
    if (joined == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        await Provider.of<OrgService>(context, listen: false).loadMyOrgs(uid);
        await _loadRoles();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _openCreate() async {
    analytics.logEvent(name: 'create_org_clicked');
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateOrganizationScreen()),
    );
    if (created == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        await Provider.of<OrgService>(context, listen: false).loadMyOrgs(uid);
        await _loadRoles();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final orgService = context.watch<OrgService>();
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    final orgs = orgService.myOrgs;
    final currentOrgId = orgService.currentOrgId;

    return AppScaffold(
      title: l.myOrganizations,
      body: RefreshIndicator(
        onRefresh: () async {
          await orgService.loadMyOrgs(uid);
          await _loadRoles();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (orgs.isEmpty)
              _emptyState(context, cs, isRtl, l)
            else
              ...orgs.map((org) {
                final isCurrent = org.id == currentOrgId;
                final role = _roles[org.id] ?? 'user';
                final isAdmin = role == 'admin';
                final isOwner = org.createdBy == uid;
                return OrgCard(
                  org: org,
                  cs: cs,
                  color: isCurrent ? cs.primary : cs.tertiary,
                  isRtl: isRtl,
                  membersLabel: l.membersCount(org.memberCount),
                  taadiasLabel: l.taadiaCount(org.taadiaCount),
                  statusLabel: isCurrent
                      ? l.currentOrg
                      : (isOwner
                          ? l.ownerLabel
                          : (isAdmin ? l.adminRole : null)),
                  statusColor: isCurrent ? const Color(0xFF00A86B) : null,
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
                      : null,
                  footerActions: [
                    if (!isCurrent)
                      OutlinedButton.icon(
                        onPressed: () => _switchOrg(org),
                        icon: Icon(Icons.swap_horiz, size: 16),
                        label: Text(l.switchToOrg),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                        ),
                      ),
                    if (isAdmin)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageOrgScreen(orgId: org.id),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings_outlined, size: 16),
                        label: Text(l.manage),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: cs.primary,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => _leaveOrg(org),
                      icon: Icon(Icons.logout, size: 16),
                      label: Text(l.leave),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: cs.error,
                      ),
                    ),
                  ],
                  onTap: isCurrent
                      ? (isAdmin
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ManageOrgScreen(orgId: org.id),
                                ),
                              );
                            }
                          : null)
                      : () => _switchOrg(org),
                );
              }),
            if (orgs.isNotEmpty) const SizedBox(height: 8),
            _joinCreateCard(context, cs, isRtl, l),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, ColorScheme cs, bool isRtl, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business_outlined, size: 32, color: cs.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            l.noOrganizationsYet,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l.joinOrCreateOrg,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _joinCreateCard(BuildContext context, ColorScheme cs, bool isRtl, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_business_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                l.orgGateSubtitle,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _openJoin,
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: Text(l.joinOrganization),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.business_outlined, size: 18),
              label: Text(l.createOrganization),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
