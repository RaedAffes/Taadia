import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/screens/admin_create_taadia.dart';
import 'package:ta3dia/screens/admin_taadia_results.dart';
import 'package:ta3dia/screens/user_taadia_results.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class PublicTaadiasListScreen extends StatefulWidget {
  @override
  _PublicTaadiasListScreenState createState() =>
      _PublicTaadiasListScreenState();
}

class _PublicTaadiasListScreenState extends State<PublicTaadiasListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isOrgAdmin = false;
  String? _lastCheckedOrgId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminRole();
      Provider.of<TaadiaService>(context, listen: false).loadTaadias();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminRole() async {
    final auth = context.read<AuthService>();
    final orgService = context.read<OrgService>();
    final uid = auth.currentUser?.uid;
    final orgId = orgService.currentOrgId;
    if (uid == null || orgId == null) {
      if (mounted) setState(() => _isOrgAdmin = false);
      return;
    }
    if (_lastCheckedOrgId == orgId) return;
    final role = await orgService.getMemberRole(orgId, uid);
    if (mounted) {
      setState(() {
        _isOrgAdmin = role == 'admin';
        _lastCheckedOrgId = orgId;
      });
    }
  }

  Future<void> _onEditTaadia(Taadia t) async {
    final l = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: t.title);
    final descCtrl = TextEditingController(text: t.description);
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.none,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.editTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
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
                  maxLines: 5,
                  minLines: 3,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, {'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim()}),
                      child: Text(l.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final taadiaService = context.watch<TaadiaService>();
    final isAdmin = _isOrgAdmin;

    final orgService = context.watch<OrgService>();
    final orgId = orgService.currentOrgId;
    if (orgId != null && _lastCheckedOrgId != orgId) {
      _lastCheckedOrgId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminRole());
    }

    final accessibleTaadias = taadiaService.taadias
        .where((t) => t.visibility != 'private')
        .toList();

    final hasItems = accessibleTaadias.isNotEmpty;

    return AppScaffold(
      title: l.publicTaadias,
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
                  SizedBox(height: 64),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : !hasItems
            ? ListView(
                children: [
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
                accessibleTaadias: accessibleTaadias,
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
  final List<Taadia> accessibleTaadias;
  final Future<void> Function(Taadia t)? onEditTaadia;
  final Future<void> Function(Taadia t)? onToggleTaadia;
  final Future<void> Function(Taadia t)? onDeleteTaadia;

  const _LazyList({
    this.scrollController,
    required this.isAdmin,
    required this.isRtl,
    required this.l,
    required this.cs,
    required this.accessibleTaadias,
    this.onEditTaadia,
    this.onToggleTaadia,
    this.onDeleteTaadia,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ListItem>[];

    if (accessibleTaadias.isNotEmpty) {
      for (final t in accessibleTaadias) {
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
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: viewHeight * 0.35),
        ),
      ],
    );
  }
}

enum _ItemType { accessible }

class _ListItem {
  final _ItemType type;
  final Taadia? taadia;

  _ListItem.accessible(this.taadia) : type = _ItemType.accessible;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
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
                child: Container(
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
                              ],
                            ),
                            if (t.description.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(t.description, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                                softWrap: true,
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr),
                            ],
                          ],
                        ),
                      ),
                      if (isAdmin) ...[
                        SizedBox(width: 8),
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
                      if (!isAdmin && onDelete != null) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onDelete!(t),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.8), size: 20),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GestureDetector(
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Spacer(),
                      if (isAdmin && onEdit != null)
                        GestureDetector(
                          onTap: () => onEdit!(t),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cs.tertiary.withOpacity(0.3)),
                            ),
                            child: Text(l.editTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.tertiary)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
