import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/string_utils.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class UserTaadiaResults extends StatefulWidget {
  final Taadia taadia;

  const UserTaadiaResults({super.key, required this.taadia});

  @override
  State<UserTaadiaResults> createState() => _UserTaadiaResultsState();
}

class _UserTaadiaResultsState extends State<UserTaadiaResults> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EvaluationService>(context, listen: false)
          .loadMyEvaluations(widget.taadia.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Evaluation> _filter(List<Evaluation> list) {
    if (_searchQuery.isEmpty) return list;
    final q = normalizeArabic(_searchQuery.toLowerCase());
    return list
        .where((e) =>
            normalizeArabic(e.studentName.toLowerCase()).contains(q) ||
            normalizeArabic(e.evaluatorName.toLowerCase()).contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final evalService = Provider.of<EvaluationService>(context);

    return AppScaffold(
      title: widget.taadia.title,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (widget.taadia.status != 'active') {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.taadiaClosed),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluateScreen(
                taadiaId: widget.taadia.id,
                taadiaTitle: widget.taadia.title,
                taadiaDescription: widget.taadia.description,
                classifications: widget.taadia.classifications,
              ),
            ),
          );
          if (context.mounted) {
            Provider.of<EvaluationService>(context, listen: false)
                .loadMyEvaluations(widget.taadia.id);
          }
        },
        child: const Icon(Icons.add),
        tooltip: l.evaluate,
      ),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: evalService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : evalService.evaluations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions,
                            size: 64, color: cs.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          l.noEvaluationsYet,
                          style: TextStyle(
                              fontSize: 18, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => Provider.of<EvaluationService>(context,
                            listen: false)
                        .loadMyEvaluations(widget.taadia.id),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: l.searchByName,
                                    prefixIcon:
                                        const Icon(Icons.search, size: 20),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear,
                                                size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(
                                                  () => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    isDense: true,
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_filter(evalService.evaluations).length} ${l.students}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildEvalCard(
                                    _filter(evalService.evaluations)[index]);
                              },
                              childCount:
                                  _filter(evalService.evaluations).length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEvalCard(Evaluation eval) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (widget.taadia.status != 'active') {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.taadiaClosed),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluateScreen(
                taadiaId: widget.taadia.id,
                taadiaTitle: widget.taadia.title,
                taadiaDescription: widget.taadia.description,
                editingEvaluation: eval,
                classifications: widget.taadia.classifications,
              ),
            ),
          );
          if (context.mounted) {
            Provider.of<EvaluationService>(context, listen: false)
                .loadMyEvaluations(widget.taadia.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Text(
                      eval.studentName.isNotEmpty
                          ? eval.studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eval.studentName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          eval.evaluatorName.isNotEmpty
                              ? eval.evaluatorName
                              : l.unknown,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: cs.outlineVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _miniChip(Icons.quiz_outlined, '${eval.numQuestions}', cs.secondary, cs),
                  if (eval.specialAhzab.isNotEmpty)
                    _miniChip(Icons.menu_book_outlined, eval.specialAhzab, cs.tertiary, cs),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.06),
                      cs.secondary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _scoreBlock(
                        Icons.notifications,
                        l.totalIchaarat,
                        '${eval.totalIchaarat}',
                        cs.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _scoreBlock(
                        Icons.record_voice_over,
                        l.totalTaalakin,
                        '${eval.totalTaalakin}',
                        cs.secondary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
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
                                  child: Text(l.deleteEvaluation, style: TextStyle(color: cs.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await Provider.of<EvaluationService>(context, listen: false)
                                .deleteEvaluation(eval.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (eval.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          eval.note,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _scoreBlock(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color, ColorScheme cs) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
