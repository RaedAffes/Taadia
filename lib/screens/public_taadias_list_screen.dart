import 'package:flutter/material.dart';
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
import 'package:ta3dia/screens/admin_taadia_results.dart';
import 'package:ta3dia/screens/create_private_taadia_screen.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class PublicTaadiasListScreen extends StatefulWidget {
  @override
  _PublicTaadiasListScreenState createState() =>
      _PublicTaadiasListScreenState();
}

class _PublicTaadiasListScreenState extends State<PublicTaadiasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaadiaService>(context, listen: false).loadTaadias();
      Provider.of<GroupService>(context, listen: false).loadGroups();
    });
  }

  void _showCodeEntryDialog() {
    final l = AppLocalizations.of(context)!;
    final codeController = TextEditingController();

    void submitCode(BuildContext ctx) async {
      final code = codeController.text.trim();
      if (code.length != 4) return;
      final taadiaService =
          Provider.of<TaadiaService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final codeLookup =
          Provider.of<CodeLookupService>(context, listen: false);

      final taadia = taadiaService.validateAccessCode(code);
      Navigator.pop(ctx);

      if (taadia != null && auth.currentUser != null) {
        final userId = auth.currentUser!.uid;
        if (taadia.accessUsers.containsKey(userId)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.alreadyHaveAccess),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        await taadiaService.cacheTaadiaByCode(taadia);
        await taadiaService.grantUserAccess(taadia.id, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.accessGranted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.taadiaNotFound),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.enterAccessCode),
        content: TextField(
          controller: codeController,
          textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: l.accessCode,
            hintText: l.accessCodeHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => submitCode(ctx),
            child: Text(l.verify),
          ),
        ],
      ),
    );
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

    final hasItems = accessibleTaadias.isNotEmpty ||
        pendingEntries.isNotEmpty ||
        resolvedEntries.isNotEmpty;

    return AppScaffold(
      title: l.publicTaadias,
      actions: [
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
                  MaterialPageRoute(
                      builder: (_) => CreatePrivateTaadiaScreen()),
                );
                if (created == true) taadiaService.loadTaadias();
              },
              child: Icon(Icons.add),
              tooltip: l.createOwnTaadia,
            )
          : null,
      body: taadiaService.isLoading && !hasItems
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => taadiaService.loadTaadias(),
              child: !hasItems
                  ? ListView(
                      children: [
                        _codeEntryBanner(l, cs),
                        SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.public, size: 64, color: cs.outlineVariant),
                              SizedBox(height: 16),
                              Text(
                                l.noTaadiasYet,
                                style: TextStyle(
                                    fontSize: 18, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
                      children: [
                        _codeEntryBanner(l, cs),
                        if (pendingEntries.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            l.pendingTaadias,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 4),
                          ...pendingEntries.map((entry) =>
                              _pendingCodeCard(entry.key, entry.value, l, cs, isRtl)),
                        ],
                        if (resolvedEntries.isNotEmpty) ...[
                          ...resolvedEntries.map((entry) =>
                              _resolvedCodeCard(entry.key, entry.value, l, cs, isRtl)),
                        ],
                        if (filteredAccessibleTaadias.isNotEmpty) ...[
                          SizedBox(height: 8),
                          ...filteredAccessibleTaadias.map((t) {
                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (isAdmin) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminTaadiaResults(taadia: t),
                                      ),
                                    );
                                  } else {
                                    if (t.status != 'active') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l.taadiaClosed),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EvaluateScreen(
                                          taadiaId: t.id,
                                          taadiaTitle: t.title,
                                          taadiaDescription: t.description,
                                          classifications: t.classifications,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cs.primaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              'assets/images/quran image.png',
                                              height: 24,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.assignment,
                                                color: cs.onPrimaryContainer,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: cs.onSurface,
                                                  ),
                                                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: t.status == 'active'
                                                            ? cs.tertiaryContainer
                                                            : cs.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        t.status == 'active'
                                                            ? l.open
                                                            : l.close,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: t.status == 'active'
                                                              ? cs.onTertiaryContainer
                                                              : cs.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        t.description.isNotEmpty
                                                            ? t.description
                                                            : '',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: cs.onSurfaceVariant,
                                                        ),
                                                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (t.accessCode.isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cs.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.vpn_key, size: 12, color: cs.primary),
                                              SizedBox(width: 4),
                                              Text(
                                                t.accessCode,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.primary,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _pendingCodeCard(String code, CachedTaadia taadia, AppLocalizations l, ColorScheme cs, bool isRtl) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluateScreen(
                taadiaId: taadia.id,
                taadiaTitle: taadia.title,
              ),
            ),
          );
        },
        child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: cs.error,
                    size: 24,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taadia.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.vpn_key, size: 12, color: cs.error),
                            SizedBox(width: 4),
                            Text(
                              code,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.error,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                  tooltip: l.deletePendingTaadia,
                  onPressed: () => _onDeletePending(code, taadia.id),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.pendingCodeMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.error,
                      ),
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
  }

  Widget _resolvedCodeCard(String code, CachedTaadia taadia, AppLocalizations l, ColorScheme cs, bool isRtl) {
    final taadiaService = context.read<TaadiaService>();
    final live = taadiaService.taadias.where((t) => t.id == taadia.id);
    final isActive = live.isNotEmpty ? live.first.status == 'active' : taadia.active;
    final liveDescription = live.isNotEmpty ? live.first.description : taadia.description;
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.taadiaClosed),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluateScreen(
                taadiaId: taadia.id,
                taadiaTitle: taadia.title,
                taadiaDescription: taadia.description,
                classifications: taadia.classifications.map((m) => ClassificationConfig.fromMap(m)).toList(),
                active: isActive,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/quran image.png',
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.assignment,
                        color: cs.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taadia.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? cs.tertiaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isActive ? l.open : l.close,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? cs.onTertiaryContainer
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                liveDescription.isNotEmpty
                                    ? liveDescription
                                    : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key, size: 12, color: cs.primary),
                    SizedBox(width: 4),
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        letterSpacing: 1,
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
  }

}
