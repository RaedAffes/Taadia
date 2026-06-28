import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/screens/private_taadia_screen.dart';
import 'package:ta3dia/screens/create_private_taadia_screen.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class PrivateTaadiasListScreen extends StatefulWidget {
  @override
  _PrivateTaadiasListScreenState createState() =>
      _PrivateTaadiasListScreenState();
}

class _PrivateTaadiasListScreenState extends State<PrivateTaadiasListScreen> {
  final Map<String, Map<String, dynamic>> _statsCache = {};
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      taadiaService.loadUserPrivateTaadias();
    });
  }

  Future<void> _loadStats(String taadiaId) async {
    if (_statsCache.containsKey(taadiaId)) return;
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    final stats = await evalService.getTaadiaStats(taadiaId);
    if (mounted) {
      setState(() => _statsCache[taadiaId] = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final taadiaService = context.watch<TaadiaService>();

    final myPrivateTaadias = taadiaService.userPrivateTaadias;

    return AppScaffold(
      title: l.manageTaadia,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => CreatePrivateTaadiaScreen()),
          );
          if (created == true) taadiaService.loadUserPrivateTaadias();
        },
        child: Icon(Icons.add),
        tooltip: l.createOwnTaadia,
      ),
      body: taadiaService.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                if (myPrivateTaadias.isNotEmpty) ...[
                  Text(
                    l.myPrivateTaadias,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l.privateTaadiaNotice,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                  SizedBox(height: 12),
                  ...myPrivateTaadias.map((t) {
                    _loadStats(t.id);
                    final stats = _statsCache[t.id];
                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrivateTaadiaScreen(
                                  taadiaId: t.id,
                                  taadiaTitle: t.title,
                                  taadiaDescription: t.description,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: cs.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: cs.onTertiaryContainer,
                                          size: 32,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                child: Text(
                                                  t.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: cs.onSurface,
                                                  ),
                                                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                ),
                                              ),
                                              if (t.accessCode.isNotEmpty)
                                                Container(
                                                  margin: EdgeInsets.only(left: 8),
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: cs.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
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
                                                          fontSize: 12,
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
                                          if (t.description.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Text(
                                                t.description,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: cs.outlineVariant,
                                      ),
                                    ],
                                  ),
                                  if (stats != null) ...[
                                    SizedBox(height: 10),
                                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _statChip(Icons.people_outline, '${stats['totalStudents']}', cs.primary, cs),
                                        SizedBox(width: 8),
                                        _statChip(Icons.quiz_outlined, '${stats['totalQuestions']}', cs.secondary, cs),
                                        if ((stats['ahzabList'] as List).isNotEmpty) ...[
                                          SizedBox(width: 8),
                                          _statChip(
                                            Icons.menu_book_outlined,
                                            (stats['ahzabList'] as List).join(', '),
                                            cs.tertiary, cs,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ] else ...[
                                    SizedBox(height: 10),
                                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: cs.error,
                                ),
                                tooltip: l.deleteEvaluation,
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l.deleteEvaluation),
                                      content: Text(l.areYouSure),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text(l.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(
                                            l.deleteEvaluation,
                                            style: TextStyle(color: cs.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final ok = await taadiaService.deleteTaadia(t.id);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    taadiaService.loadUserPrivateTaadias();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (myPrivateTaadias.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dashboard,
                            size: 64,
                            color: cs.outlineVariant,
                          ),
                          SizedBox(height: 16),
                          Text(
                            l.noTaadiasYet,
                            style: TextStyle(
                              fontSize: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            l.tapToCreateFirst,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
