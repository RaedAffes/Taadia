import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/organization_model.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/org/role_badge.dart';

class ManageOrgScreen extends StatefulWidget {
  final String? orgId;
  final bool showBackButton;

  const ManageOrgScreen({super.key, this.orgId, this.showBackButton = true});

  @override
  State<ManageOrgScreen> createState() => _ManageOrgScreenState();
}

class _ManageOrgScreenState extends State<ManageOrgScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _orgId = '';
  Organization? _org;
  bool _loadingOrg = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _orgId = widget.orgId ??
        Provider.of<OrgService>(context, listen: false).currentOrgId ??
        '';
    _loadOrg();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrg() async {
    if (_orgId.isEmpty) {
      if (mounted) setState(() => _loadingOrg = false);
      return;
    }
    final org = await context.read<OrgService>().getOrg(_orgId);
    if (mounted) {
      setState(() {
        _org = org;
        _loadingOrg = false;
      });
    }
  }

  Future<void> _confirmDeleteOrg() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final orgName = _org?.name ?? '';
    final nameCtrl = TextEditingController();
    bool canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text(l.deleteOrganization)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.deleteOrgConfirm(orgName), style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: l.typeNameToConfirm,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.error)),
                ),
                onChanged: (v) =>
                    setDialogState(() => canDelete = v.trim() == orgName),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
              child: Text(l.deleteOrganization, style: TextStyle(color: cs.error)),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    if (confirmed != true || !mounted) return;
    await context.read<OrgService>().deleteOrganization(_orgId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.organizationDeleted),
      backgroundColor: _successColor,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';

    if (_loadingOrg) {
      return AppScaffold(
        title: l.manageOrganization,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_orgId.isEmpty) {
      return AppScaffold(
        title: l.manageOrganization,
        body: Center(child: Text(l.noOrganizations)),
      );
    }

    return AppScaffold(
      title: l.manageOrganization,
      subtitle: _org?.name,
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: cs.error, size: 22),
          onPressed: _confirmDeleteOrg,
          tooltip: l.deleteOrganization,
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                Tab(text: l.membersTab),
                Tab(text: l.resetPasswordTab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  orgId: _orgId,
                  ownerUid: _org?.createdBy ?? '',
                  cs: cs,
                  isRtl: isRtl,
                  searchCtrl: _searchCtrl,
                  searchQuery: _searchQuery,
                  onSearch: (v) => setState(() => _searchQuery = v),
                ),
                _ResetPasswordTab(
                  orgId: _orgId,
                  cs: cs,
                  isRtl: isRtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _successColor = Color(0xFF2E9E5A);

class _MembersTab extends StatefulWidget {
  final String orgId;
  final String ownerUid;
  final ColorScheme cs;
  final bool isRtl;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearch;

  const _MembersTab({
    required this.orgId,
    required this.ownerUid,
    required this.cs,
    required this.isRtl,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearch,
  });

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              _filterChip(l.all, 'all'),
              const SizedBox(width: 6),
              _filterChip(l.adminRole, 'admin'),
              const SizedBox(width: 6),
              _filterChip(l.member, 'user'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: widget.searchCtrl,
            onChanged: widget.onSearch,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: l.searchMembers,
              hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search_rounded, size: 17, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(widget.orgId)
                .collection('members')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              var docs = snapshot.data!.docs;
              if (widget.searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final name = (d.data() as Map<String, dynamic>)['name'] ?? '';
                  return name.toString().toLowerCase().contains(widget.searchQuery);
                }).toList();
              }
              if (_roleFilter != 'all') {
                docs = docs.where((d) =>
                    (d.data() as Map<String, dynamic>)['role'] == _roleFilter).toList();
              }
              if (docs.isEmpty) return _emptyState(cs, l);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: docs.length,
                itemBuilder: (context, index) =>
                    _memberCard(docs[index], cs, l),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _memberCard(QueryDocumentSnapshot doc, ColorScheme cs, AppLocalizations l) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '—';
    final role = data['role'] ?? 'user';
    final uid = data['uid'] ?? doc.id;
    final isAdmin = role == 'admin';
    final isOwner = uid == widget.ownerUid;
    final initials = name
        .toString()
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    final accent = isAdmin ? cs.primary : cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name.toString(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isOwner) ...[
                        RoleBadge(
                          label: l.ownerLabel,
                          cs: cs,
                          color: const Color(0xFFD4910A),
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ] else if (isAdmin) ...[
                        RoleBadge(
                          label: l.adminRole,
                          cs: cs,
                          color: cs.primary,
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                      ] else ...[
                        RoleBadge(label: l.member, cs: cs, color: cs.onSurfaceVariant),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String?>(
                    future: context.read<OrgService>().getMemberEmail(uid),
                    builder: (ctx, snap) => Text(
                      snap.data ?? '—',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              enabled: !isOwner,
              icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
              onSelected: (v) {
                if (v == 'toggle') {
                  _toggleRole(uid, name.toString(), isAdmin);
                } else if (v == 'remove') {
                  _removeMember(uid, name.toString());
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 16,
                        color: isAdmin ? cs.error : cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAdmin ? l.demoteFromAdmin : l.promoteToAdmin,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, size: 16, color: cs.error),
                      const SizedBox(width: 8),
                      Text(
                        l.removeFromOrg,
                        style: TextStyle(fontSize: 13, color: cs.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _roleFilter == value;
    final primary = widget.cs.primary;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primary : widget.cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : widget.cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(l.noMembersYet, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _toggleRole(String uid, String name, bool isAdmin) async {
    final l = AppLocalizations.of(context)!;
    final orgService = context.read<OrgService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAdmin ? l.demoteFromAdmin : l.promoteToAdmin),
        content: Text(isAdmin
            ? l.demoteFromAdmin
            : l.promoteToAdmin),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
        ],
      ),
    );
    if (confirmed == true) {
      await orgService.toggleMemberRole(widget.orgId, uid);
    }
  }

  Future<void> _removeMember(String uid, String name) async {
    final l = AppLocalizations.of(context)!;
    final cs = widget.cs;
    final orgService = context.read<OrgService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.removeFromOrg),
        content: Text(l.removeMemberConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.removeFromOrg, style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await orgService.removeMember(widget.orgId, uid);
    }
  }
}

class _ResetPasswordTab extends StatefulWidget {
  final String orgId;
  final ColorScheme cs;
  final bool isRtl;

  const _ResetPasswordTab({required this.orgId, required this.cs, required this.isRtl});

  @override
  State<_ResetPasswordTab> createState() => _ResetPasswordTabState();
}

class _ResetPasswordTabState extends State<_ResetPasswordTab> {
  String? _currentPassword;
  bool _loading = true;
  bool _obscure = true;
  late TextEditingController _newPassCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _newPassCtrl = TextEditingController();
    _loadPassword();
  }

  @override
  void dispose() {
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPassword() async {
    final pw = await context.read<OrgService>().loadOrgPassword(widget.orgId);
    if (mounted) {
      setState(() {
        _currentPassword = pw;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = widget.cs;

    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            cs: cs,
            icon: Icons.lock_outline_rounded,
            title: l.currentPassword,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.key_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _obscure
                          ? ('•' * (_currentPassword?.length ?? 0))
                          : (_currentPassword ?? '—'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: _obscure ? 2 : 0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            cs: cs,
            icon: Icons.edit_rounded,
            title: l.changePassword,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l.newPassword,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
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
                        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.4), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _saving
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                      )
                    : IconButton(
                        onPressed: () async {
                          final newPw = _newPassCtrl.text.trim();
                          if (newPw.isEmpty) return;
                          final orgService = context.read<OrgService>();
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _saving = true);
                          await orgService.updateOrgPassword(widget.orgId, newPw);
                          setState(() {
                            _saving = false;
                            _currentPassword = newPw;
                            _newPassCtrl.clear();
                          });
                          messenger.showSnackBar(SnackBar(
                            content: Text(l.updatedSuccess),
                            backgroundColor: _successColor,
                          ));
                        },
                        icon: Icon(Icons.check_circle_rounded, color: cs.primary, size: 28),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            cs: cs,
            icon: Icons.info_outline_rounded,
            title: l.info,
            child: Text(
              l.joinPasswordHint,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
