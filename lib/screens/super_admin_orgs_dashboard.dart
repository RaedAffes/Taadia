import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/organization_model.dart';
import 'package:ta3dia/screens/manage_org_screen.dart';
import 'package:ta3dia/services/super_admin_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/org/org_card.dart';

const _pendingColor = Color(0xFFD4910A);
const _successColor = Color(0xFF2E9E5A);

class SuperAdminOrgsDashboard extends StatefulWidget {
  const SuperAdminOrgsDashboard({super.key});

  @override
  State<SuperAdminOrgsDashboard> createState() => _SuperAdminOrgsDashboardState();
}

class _SuperAdminOrgsDashboardState extends State<SuperAdminOrgsDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SuperAdminService>(context, listen: false).loadAllOrgs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Organization> _filter(List<Organization> orgs) {
    if (_searchQuery.isEmpty) return orgs;
    return orgs.where((o) => o.name.toLowerCase().contains(_searchQuery)).toList();
  }

  Future<void> _approve(Organization org) async {
    final l = AppLocalizations.of(context)!;
    final ok = await context.read<SuperAdminService>().approveOrg(org.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? l.organizationApproved : l.updateFailed),
      backgroundColor: ok ? _successColor : Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _reject(Organization org) async {
    final l = AppLocalizations.of(context)!;
    final ok = await context.read<SuperAdminService>().rejectOrg(org.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? l.organizationRejected : l.updateFailed),
      backgroundColor: ok ? _pendingColor : Theme.of(context).colorScheme.error,
    ));
  }

  void _openManage(Organization org) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageOrgScreen(orgId: org.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final service = context.watch<SuperAdminService>();
    final pending = _filter(service.pendingOrgs);
    final approved = _filter(service.approvedOrgs);

    return AppScaffold(
      title: l.manageOrganizations,
      body: Column(
        children: [
          _buildSearchBar(cs, l),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: '${l.pendingOrgs} (${service.pendingOrgs.length})'),
                Tab(text: '${l.approvedOrgs} (${service.approvedOrgs.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _orgsList(context, service, pending, isRtl, cs, l, pendingTab: true),
                _orgsList(context, service, approved, isRtl, cs, l, pendingTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orgsList(
    BuildContext context,
    SuperAdminService service,
    List<Organization> orgs,
    bool isRtl,
    ColorScheme cs,
    AppLocalizations l, {
    required bool pendingTab,
  }) {
    return RefreshIndicator(
      onRefresh: () => service.loadAllOrgs(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (service.isLoading && orgs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (orgs.isEmpty)
            _emptyState(cs, l)
          else
            ...orgs.map(
              (org) => pendingTab ? _pendingCard(org, cs, isRtl, l) : _approvedCard(org, cs, isRtl, l),
            ),
        ],
      ),
    );
  }

  Widget _pendingCard(Organization org, ColorScheme cs, bool isRtl, AppLocalizations l) {
    final created = org.createdAt;
    final dateStr = '${created.day}/${created.month}/${created.year}';
    return OrgCard(
      org: org,
      cs: cs,
      color: _pendingColor,
      isRtl: isRtl,
      membersLabel: l.membersCount(org.memberCount),
      taadiasLabel: l.taadiaCount(org.taadiaCount),
      subtitle: org.creatorName.isNotEmpty
          ? '${l.createdBy} ${org.creatorName}${dateStr.isNotEmpty ? ' · $dateStr' : ''}'
          : null,
      statusLabel: l.pending,
      statusColor: Colors.white,
      footerActions: [
        OutlinedButton.icon(
          onPressed: () => _reject(org),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: Text(l.reject),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _approve(org),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: Text(l.approve),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: _successColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _approvedCard(Organization org, ColorScheme cs, bool isRtl, AppLocalizations l) {
    return OrgCard(
      org: org,
      cs: cs,
      color: cs.primary,
      isRtl: isRtl,
      membersLabel: l.membersCount(org.memberCount),
      taadiasLabel: l.taadiaCount(org.taadiaCount),
      statusLabel: l.approved,
      statusColor: _successColor,
      trailing: Icon(
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        color: Colors.white,
        size: 24,
      ),
      footerActions: [
        TextButton.icon(
          onPressed: () => _openManage(org),
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: Text(l.manage),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: cs.primary,
          ),
        ),
      ],
      onTap: () => _openManage(org),
    );
  }

  Widget _buildSearchBar(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: l.searchByName,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 32,
              color: cs.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.noOrganizations,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
