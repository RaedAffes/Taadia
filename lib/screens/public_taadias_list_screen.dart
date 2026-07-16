import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/code_lookup_service.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/screens/admin_create_taadia.dart';
import 'package:ta3dia/screens/admin_taadia_results.dart';
import 'package:ta3dia/screens/user_taadia_results.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/gift_reveal_card.dart';

class PublicTaadiasListScreen extends StatefulWidget {
  @override
  _PublicTaadiasListScreenState createState() =>
      _PublicTaadiasListScreenState();
}

class _PublicTaadiasListScreenState extends State<PublicTaadiasListScreen> {
  String? _justAccessedId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaadiaService>(context, listen: false).loadTaadias();
      Provider.of<GroupService>(context, listen: false).loadGroups();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCodeEntryDialog() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CodeEntryDialog(
        isRtl: isRtl,
        l: l,
        cs: cs,
        onCodeSubmitted: (code) async {
          final taadiaService =
              Provider.of<TaadiaService>(context, listen: false);
          final auth = Provider.of<AuthService>(context, listen: false);
          final l2 = AppLocalizations.of(context)!;

          final taadia = taadiaService.validateAccessCode(code);
          Navigator.pop(ctx);

          if (taadia != null && auth.currentUser != null) {
            final userId = auth.currentUser!.uid;
            if (taadia.accessUsers.containsKey(userId)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l2.alreadyHaveAccess),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }
            await taadiaService.cacheTaadiaByCode(taadia);
            await taadiaService.grantUserAccess(taadia.id, userId);
            if (!mounted) return;
            setState(() => _justAccessedId = taadia.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l2.accessGranted),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l2.taadiaNotFound),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _onEditTaadia(Taadia t) async {
    final l = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: t.title);
    final descCtrl = TextEditingController(text: t.description);
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(labelText: l.assessmentTitle, hintText: t.title),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(labelText: l.descriptionOptional, hintText: l.descriptionHint),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim()}),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result != null) {
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      final updates = <String, dynamic>{};
      if (result['title']!.isNotEmpty && result['title'] != t.title) updates['title'] = result['title'];
      if (result['description'] != t.description) updates['description'] = result['description'];
      if (updates.isNotEmpty) {
        final ok = await taadiaService.updateTaadia(t.id, title: updates['title'], description: updates['description']);
        if (mounted && !ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.updateFailed), backgroundColor: cs.error));
        }
      }
    }
  }

  Future<void> _onToggleTaadia(Taadia t) async {
    final taadiaService = Provider.of<TaadiaService>(context, listen: false);
    if (t.status == 'active') {
      await taadiaService.closeTaadia(t.id);
    } else {
      await taadiaService.openTaadia(t.id);
    }
  }

  Future<void> _onDeleteTaadia(Taadia t) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirm(t.title)),
        content: Text(l.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: TextStyle(color: cs.error))),
        ],
      ),
    );
    if (confirmed == true) {
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      await taadiaService.deleteTaadia(t.id);
    }
  }

  Widget _codeEntryBanner(AppLocalizations l, ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.1), cs.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showCodeEntryDialog,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.vpn_key, color: cs.primary, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.joinWithCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l.joinWithCodeDesc,
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
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDeletePending(String code, String taadiaId) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deletePendingTaadia),
        content: Text(l.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final codeLookup = Provider.of<CodeLookupService>(context, listen: false);
    final offlineQueue = Provider.of<OfflineQueueService>(context, listen: false);
    final evalService = Provider.of<EvaluationService>(context, listen: false);

    await offlineQueue.removePendingEvaluationsByCode(code);

    final localEvals = evalService.evaluations
        .where((e) => e.taadiaId == taadiaId)
        .toList();
    for (final e in localEvals) {
      await evalService.deleteEvaluation(e.id);
    }

    await codeLookup.removeEntry(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final taadiaService = context.watch<TaadiaService>();
    final auth = context.watch<AuthService>();
    final groupService = context.watch<GroupService>();
    final codeLookup = context.watch<CodeLookupService>();
    final isAdmin = auth.isAdmin;
    final userId = auth.currentUser?.uid ?? '';

    final userGroupIds = groupService.getUserGroupIds(userId);
    final accessibleTaadias = isAdmin
        ? taadiaService.taadias.where((t) => t.visibility != 'private').toList()
        : taadiaService.getAccessibleTaadias(userId, userGroupIds);

    final pendingEntries = codeLookup.allEntries
        .where((e) => e.value.id.startsWith('pending_'))
        .toList();
    final resolvedEntries = codeLookup.allEntries
        .where((e) => !e.value.id.startsWith('pending_'))
        .toList();
    final resolvedTaadiaIds = resolvedEntries.map((e) => e.value.id).toSet();
    final filteredAccessibleTaadias = accessibleTaadias
        .where((t) => !resolvedTaadiaIds.contains(t.id))
        .toList();

    if (_justAccessedId != null) {
      final rIdx = resolvedEntries.indexWhere((e) => e.value.id == _justAccessedId);
      if (rIdx > 0) {
        resolvedEntries.insert(0, resolvedEntries.removeAt(rIdx));
      }
      final pIdx = pendingEntries.indexWhere((e) => e.value.id == _justAccessedId);
      if (pIdx > 0) {
        pendingEntries.insert(0, pendingEntries.removeAt(pIdx));
      }
      final aIdx = filteredAccessibleTaadias.indexWhere((t) => t.id == _justAccessedId);
      if (aIdx > 0) {
        filteredAccessibleTaadias.insert(0, filteredAccessibleTaadias.removeAt(aIdx));
      }
    }

    final hasItems = accessibleTaadias.isNotEmpty ||
        pendingEntries.isNotEmpty ||
        resolvedEntries.isNotEmpty;

    return AppScaffold(
      title: l.publicTaadias,
      actions: [
        if (!isAdmin)
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: l.enterAccessCode,
            onPressed: _showCodeEntryDialog,
          ),
      ],
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => CreateTaadiaScreen()),
                );
                if (created == true) taadiaService.loadTaadias();
              },
              child: Icon(Icons.add),
              tooltip: l.createOwnTaadia,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => taadiaService.loadTaadias(),
        child: !hasItems && taadiaService.isLoading
            ? ListView(
                children: [
                  if (!isAdmin) _codeEntryBanner(l, cs),
                  SizedBox(height: 64),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : !hasItems
            ? ListView(
                children: [
                  if (!isAdmin) _codeEntryBanner(l, cs),
                  SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.public, size: 64, color: cs.outlineVariant),
                        SizedBox(height: 16),
                        Text(
                          l.noTaadiasYet,
                          style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _LazyList(
                scrollController: _scrollController,
                isAdmin: isAdmin,
                isRtl: isRtl,
                l: l,
                cs: cs,
                pendingEntries: pendingEntries,
                resolvedEntries: resolvedEntries,
                filteredAccessibleTaadias: filteredAccessibleTaadias,
                justAccessedId: _justAccessedId,
                onCodeEntry: _showCodeEntryDialog,
                onDeletePending: _onDeletePending,
                onEditTaadia: _onEditTaadia,
                onToggleTaadia: _onToggleTaadia,
                onDeleteTaadia: _onDeleteTaadia,
              ),
      ),
    );
  }

}

class _LazyList extends StatelessWidget {
  final ScrollController? scrollController;
  final bool isAdmin;
  final bool isRtl;
  final AppLocalizations l;
  final ColorScheme cs;
  final List<MapEntry<String, CachedTaadia>> pendingEntries;
  final List<MapEntry<String, CachedTaadia>> resolvedEntries;
  final List<Taadia> filteredAccessibleTaadias;
  final String? justAccessedId;
  final VoidCallback onCodeEntry;
  final Future<void> Function(String code, String taadiaId) onDeletePending;
  final Future<void> Function(Taadia t)? onEditTaadia;
  final Future<void> Function(Taadia t)? onToggleTaadia;
  final Future<void> Function(Taadia t)? onDeleteTaadia;

  const _LazyList({
    this.scrollController,
    required this.isAdmin,
    required this.isRtl,
    required this.l,
    required this.cs,
    required this.pendingEntries,
    required this.resolvedEntries,
    required this.filteredAccessibleTaadias,
    this.justAccessedId,
    required this.onCodeEntry,
    required this.onDeletePending,
    this.onEditTaadia,
    this.onToggleTaadia,
    this.onDeleteTaadia,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ListItem>[];

    if (!isAdmin) {
      items.add(_ListItem.banner());
    }
    if (!isAdmin && pendingEntries.isNotEmpty) {
      items.add(_ListItem.sectionHeader(l.pendingTaadias));
      for (final e in pendingEntries) {
        items.add(_ListItem.pending(e.key, e.value));
      }
    }
    if (!isAdmin && resolvedEntries.isNotEmpty) {
      for (final e in resolvedEntries) {
        items.add(_ListItem.resolved(e.key, e.value));
      }
    }
    if (filteredAccessibleTaadias.isNotEmpty) {
      if (!isAdmin && (resolvedEntries.isNotEmpty || pendingEntries.isNotEmpty)) {
        items.add(_ListItem.sectionHeader(''));
      }
      for (final t in filteredAccessibleTaadias) {
        items.add(_ListItem.accessible(t));
      }
    }

    final viewHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: 8, left: 16, right: 16),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              switch (item.type) {
                case _ItemType.banner:
                  return onCodeEntry != null
                      ? _buildBanner(context)
                      : const SizedBox.shrink();
                case _ItemType.sectionHeader:
                  if (item.title == null || item.title!.isEmpty) {
                    return const SizedBox(height: 8);
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4, top: 8),
                    child: Text(
                      item.title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                case _ItemType.pending:
                  return _PendingCard(
                    code: item.code!,
                    taadia: item.cachedTaadia!,
                    l: l,
                    cs: cs,
                    isRtl: isRtl,
                    onDelete: () =>
                        onDeletePending(item.code!, item.cachedTaadia!.id),
                  );
                case _ItemType.resolved:
                  return _ResolvedCard(
                    key: ValueKey('gift_${item.cachedTaadia!.id}'),
                    code: item.code!,
                    taadia: item.cachedTaadia!,
                    l: l,
                    cs: cs,
                    isRtl: isRtl,
                    showGift: justAccessedId == item.cachedTaadia!.id,
                  );
                case _ItemType.accessible:
                  return _AccessibleCard(
                    taadia: item.taadia!,
                    l: l,
                    cs: cs,
                    isRtl: isRtl,
                    isAdmin: isAdmin,
                    onEdit: onEditTaadia,
                    onToggle: onToggleTaadia,
                    onDelete: onDeleteTaadia,
                  );
              }
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: viewHeight * 0.35),
        ),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.1), cs.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onCodeEntry,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.vpn_key, color: cs.primary, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.joinWithCode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      SizedBox(height: 4),
                      Text(l.joinWithCodeDesc, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ItemType { banner, sectionHeader, pending, resolved, accessible }

class _ListItem {
  final _ItemType type;
  final String? title;
  final String? code;
  final CachedTaadia? cachedTaadia;
  final Taadia? taadia;

  _ListItem.banner() : type = _ItemType.banner, title = null, code = null, cachedTaadia = null, taadia = null;
  _ListItem.sectionHeader(this.title) : type = _ItemType.sectionHeader, code = null, cachedTaadia = null, taadia = null;
  _ListItem.pending(this.code, this.cachedTaadia) : type = _ItemType.pending, title = null, taadia = null;
  _ListItem.resolved(this.code, this.cachedTaadia) : type = _ItemType.resolved, title = null, taadia = null;
  _ListItem.accessible(this.taadia) : type = _ItemType.accessible, title = null, code = null, cachedTaadia = null;
}

class _PendingCard extends StatelessWidget {
  final String code;
  final CachedTaadia taadia;
  final AppLocalizations l;
  final ColorScheme cs;
  final bool isRtl;
  final VoidCallback onDelete;

  const _PendingCard({
    required this.code,
    required this.taadia,
    required this.l,
    required this.cs,
    required this.isRtl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cs.error.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EvaluateScreen(taadiaId: taadia.id, taadiaTitle: taadia.title),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.error, cs.error.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(taadia.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white), textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(l.pendingCodeMessage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.8), size: 22),
                      tooltip: l.deletePendingTaadia,
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key, size: 14, color: cs.error),
                    SizedBox(width: 8),
                    Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.error, letterSpacing: 2)),
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

class _ResolvedCard extends StatelessWidget {
  final String code;
  final CachedTaadia taadia;
  final AppLocalizations l;
  final ColorScheme cs;
  final bool isRtl;
  final bool showGift;

  const _ResolvedCard({
    super.key,
    required this.code,
    required this.taadia,
    required this.l,
    required this.cs,
    required this.isRtl,
    this.showGift = false,
  });

  @override
  Widget build(BuildContext context) {
    final taadiaService = context.read<TaadiaService>();
    final auth = context.read<AuthService>();
    final isAdmin = auth.isAdmin;
    final live = taadiaService.taadias.where((t) => t.id == taadia.id);
    final isActive = live.isNotEmpty ? live.first.status == 'active' : taadia.active;
    final liveDescription = live.isNotEmpty ? live.first.description : taadia.description;
    final card = Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!isActive) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.taadiaClosed), backgroundColor: Colors.red));
              return;
            }
            if (isAdmin) {
              if (live.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTaadiaResults(taadia: live.first)));
              }
            } else {
              if (live.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserTaadiaResults(taadia: live.first)));
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EvaluateScreen(
                    taadiaId: taadia.id,
                    taadiaTitle: taadia.title,
                    taadiaDescription: taadia.description,
                    classifications: taadia.classifications.map((m) => ClassificationConfig.fromMap(m)).toList(),
                    active: isActive,
                  ),
                ));
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: Image.asset('assets/images/quran image.png', height: 28, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.auto_stories, color: Colors.white, size: 28)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(taadia.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 7, height: 7, decoration: BoxDecoration(color: isActive ? Color(0xFF00A86B) : Colors.white54, shape: BoxShape.circle)),
                                    SizedBox(width: 6),
                                    Text(isActive ? l.open : l.close, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                              if (liveDescription.isNotEmpty) ...[
                                SizedBox(width: 10),
                                Expanded(child: Text(liveDescription, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key, size: 14, color: cs.primary),
                    SizedBox(width: 8),
                    Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 2)),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: cs.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 16, color: cs.primary),
                          SizedBox(width: 4),
                          Text(l.startTaadia, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return showGift ? GiftRevealCard(showGift: true, child: card) : card;
  }
}

class _AccessibleCard extends StatelessWidget {
  final Taadia taadia;
  final AppLocalizations l;
  final ColorScheme cs;
  final bool isRtl;
  final bool isAdmin;
  final Future<void> Function(Taadia t)? onEdit;
  final Future<void> Function(Taadia t)? onToggle;
  final Future<void> Function(Taadia t)? onDelete;

  const _AccessibleCard({
    required this.taadia,
    required this.l,
    required this.cs,
    required this.isRtl,
    required this.isAdmin,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = taadia;
    final tActive = t.status == 'active';
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(0.06), blurRadius: 16, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isAdmin) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTaadiaResults(taadia: t)));
            } else {
              if (!tActive) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.taadiaClosed), backgroundColor: Colors.red));
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserTaadiaResults(taadia: t)));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.tertiary, cs.tertiary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: Image.asset('assets/images/quran image.png', height: 28, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.auto_stories, color: Colors.white, size: 28)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tActive ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 7, height: 7, decoration: BoxDecoration(color: tActive ? Color(0xFF00A86B) : Colors.white54, shape: BoxShape.circle)),
                                    SizedBox(width: 6),
                                    Text(tActive ? l.open : l.close, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                              if (t.description.isNotEmpty) ...[
                                SizedBox(width: 10),
                                Expanded(child: Text(t.description, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () => onEdit?.call(t),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(Icons.more_vert, color: Colors.white, size: 22),
                        onSelected: (v) {
                          if (v == 'toggle' && onToggle != null) onToggle!(t);
                          if (v == 'delete' && onDelete != null) onDelete!(t);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'toggle', child: Row(children: [Icon(tActive ? Icons.lock_outline : Icons.lock_open, size: 18), SizedBox(width: 8), Text(tActive ? l.close : l.open)])),
                          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: cs.error), SizedBox(width: 8), Text(l.delete, style: TextStyle(color: cs.error))])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (t.accessCode.isNotEmpty || isAdmin)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      if (t.accessCode.isNotEmpty) ...[
                        Icon(Icons.vpn_key, size: 14, color: cs.tertiary),
                        SizedBox(width: 8),
                        Text(t.accessCode, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.tertiary, letterSpacing: 2)),
                        Spacer(),
                      ] else
                        Spacer(),
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

class _CodeEntryDialog extends StatefulWidget {
  final bool isRtl;
  final AppLocalizations l;
  final ColorScheme cs;
  final Future<void> Function(String code) onCodeSubmitted;

  const _CodeEntryDialog({
    required this.isRtl,
    required this.l,
    required this.cs,
    required this.onCodeSubmitted,
  });

  @override
  State<_CodeEntryDialog> createState() => _CodeEntryDialogState();
}

class _CodeEntryDialogState extends State<_CodeEntryDialog> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (i) {
      return FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[i].text.isEmpty &&
              i > 0) {
            _controllers[i - 1].clear();
            _focusNodes[i - 1].requestFocus();
            setState(() {});
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final l = widget.l;
    final isRtl = widget.isRtl;
    final code = _code;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      backgroundColor: cs.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.vpn_key_rounded, size: 28, color: cs.onPrimary),
            ),
            SizedBox(height: 20),
            Text(
              l.enterAccessCode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              isRtl
                  ? 'أدخل رمز الوصول المكون من 4 أرقام'
                  : 'Enter the 4-digit access code',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isFilled = _controllers[i].text.isNotEmpty;
                  final isFocused = _focusNodes[i].hasFocus;
                  return Container(
                    width: 56,
                    height: 64,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isFocused
                                ? cs.primary
                                : isFilled
                                    ? cs.primary.withValues(alpha: 0.6)
                                    : cs.outlineVariant.withValues(alpha: 0.5),
                            width: isFocused ? 2.5 : isFilled ? 2 : 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isFilled
                                ? cs.primary.withValues(alpha: 0.6)
                                : cs.outlineVariant.withValues(alpha: 0.5),
                            width: isFilled ? 2 : 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: cs.primary,
                            width: 2.5,
                          ),
                        ),
                        filled: true,
                        fillColor: isFocused
                            ? cs.primaryContainer.withValues(alpha: 0.2)
                            : isFilled
                                ? cs.primaryContainer.withValues(alpha: 0.1)
                                : cs.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Text(
                      l.cancel,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (code.length == 4 && !_submitting)
                        ? () async {
                            setState(() => _submitting = true);
                            await widget.onCodeSubmitted(code);
                            if (mounted) setState(() => _submitting = false);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _submitting ? (isRtl ? 'جاري التحقق...' : 'Verifying...') : l.verify,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
