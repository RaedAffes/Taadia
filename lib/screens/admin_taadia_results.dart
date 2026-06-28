import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/models/formula_config.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/screens/admin_evaluation_detail.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class AdminTaadiaResults extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Taadia taadia;
  AdminTaadiaResults({required this.taadia});

  @override
  _AdminTaadiaResultsState createState() => _AdminTaadiaResultsState();
}

class _AdminTaadiaResultsState extends State<AdminTaadiaResults> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<String> _categoryFilter = {};
  final Map<String, String> _classificationFilters = {};
  List<String> get _taadiaCategories => widget.taadia.categories ?? [];
  List<ClassificationConfig> get _taadiaClassifications => widget.taadia.classifications;
  bool _showClassement = false;
  late String _currentFormula;
  @override
  void initState() {
    _currentFormula = widget.taadia.formula;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(
        screenName: 'admin_taadia_results_screen',
        parameters: {
          'taadia_id': widget.taadia.id,
          'taadia_title': widget.taadia.title,
        },
      );
      Provider.of<EvaluationService>(
        context,
        listen: false,
      ).loadEvaluations(widget.taadia.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calcResult(Evaluation e) {
    final x = e.questions.length;
    if (x == 0) return 0;
    final y = _currentFormula == 'jihawiya' ? 20.0 / x : 10.0 / x;
    double m = 0;
    for (final q in e.questions) {
      m += 0.25 * q.ichaarat + 1.0 * q.taalakin;
    }
    return 20 - y * m;
  }

  List<Evaluation> _filter(List<Evaluation> list) {
    var result = list;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) => e.studentName.toLowerCase().contains(q))
          .toList();
    }
    if (_categoryFilter.isNotEmpty) {
      result = result.where((e) => e.categories.any((c) => _categoryFilter.contains(c))).toList();
    }
    for (final entry in _classificationFilters.entries) {
      if (entry.value.isNotEmpty) {
        result = result.where((e) {
          final val = e.classificationValues[entry.key];
          return val == entry.value;
        }).toList();
      }
    }
    return result;
  }

  List<Evaluation> _sortedWithRank(List<Evaluation> list) {
    final sorted = List<Evaluation>.from(list)
      ..sort((a, b) => _calcResult(b).compareTo(_calcResult(a)));
    return sorted;
  }

  Future<void> _showFormulaDialog() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.functions, color: cs.primary),
            SizedBox(width: 8),
            Text(l.formula),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.formulaDesc,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            SizedBox(height: 16),
            _formulaOption(
              ctx,
              'mahalia',
              'محلية (Mahalia)',
              Icons.location_city,
              cs.primary,
              _currentFormula,
            ),
            SizedBox(height: 8),
            _formulaOption(
              ctx,
              'jihawiya',
              'جهوية (Jihawiya)',
              Icons.public,
              cs.secondary,
              _currentFormula,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );

    if (result != null && result != _currentFormula && mounted) {
      final svc = Provider.of<TaadiaService>(context, listen: false);
      await svc.updateFormula(widget.taadia.id, result);
      if (mounted) {
        setState(() => _currentFormula = result);
      }
    }
  }

  Widget _formulaOption(
    BuildContext ctx,
    String value,
    String label,
    IconData icon,
    Color color,
    String current,
  ) {
    final selected = current == value;
    return InkWell(
      onTap: () => Navigator.pop(ctx, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Theme.of(ctx).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? color : null,
              ),
            ),
            Spacer(),
            if (selected) Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  String _formulaLabel(String f, AppLocalizations l) {
    return FormulaConfig.fromJson(
      f,
    ).displayLabel(l.totalIchaarat, l.totalTaalakin);
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EvaluateScreen(
              taadiaId: widget.taadia.id,
              taadiaTitle: widget.taadia.title,
              taadiaDescription: widget.taadia.description,
              classifications: widget.taadia.classifications,
            ),
          ),
        ),
        child: Icon(Icons.add),
        tooltip: l.evaluate,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.download),
          tooltip: 'Download PDF',
          onPressed: _downloadPdf,
        ),
        if (widget.taadia.isPrivate)
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
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
                final svc = Provider.of<TaadiaService>(context, listen: false);
                final ok = await svc.deleteTaadia(widget.taadia.id);
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete'),
                      backgroundColor: cs.error,
                    ),
                  );
                }
              }
            },
          ),
      ],
      body: Stack(
        children: [
          evalService.isLoading
              ? Center(child: CircularProgressIndicator())
              : evalService.evaluations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 64,
                        color: cs.outlineVariant,
                      ),
                      SizedBox(height: 16),
                      Text(
                        l.waitingForTeachers,
                        style: TextStyle(
                          fontSize: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final allEvals = evalService.evaluations;
                    final filtered = _filter(allEvals);
                    final showRank = widget.taadia.isPrivate || _showClassement;
                    final ranked = showRank
                        ? _sortedWithRank(filtered)
                        : filtered;

                    return RefreshIndicator(
                      onRefresh: () =>
                          evalService.loadEvaluations(widget.taadia.id),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 16),
                                  TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: l.searchByName,
                                      prefixIcon: Icon(Icons.search, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(
                                                  () => _searchQuery = '',
                                                );
                                              },
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      isDense: true,
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                  ),
                                  if (widget.taadia.accessCode.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.vpn_key, size: 20, color: cs.primary),
                                            SizedBox(width: 8),
                                            Text(
                                              '${l.accessCode}: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            Text(
                                              widget.taadia.accessCode,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: cs.primary,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            Spacer(),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () {
                                                final cb = Clipboard.setData(ClipboardData(text: widget.taadia.accessCode));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(l.copied), duration: Duration(seconds: 1)),
                                                );
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.copy, size: 18, color: cs.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cs.tertiaryContainer.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: cs.tertiary.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.functions,
                                                size: 16,
                                                color: cs.tertiary,
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  _formulaLabel(
                                                    _currentFormula,
                                                    l,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        cs.onTertiaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: Icon(
                                                    Icons.functions,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    l.formula,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        cs.secondaryContainer,
                                                    foregroundColor:
                                                        cs.onSecondaryContainer,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: _showFormulaDialog,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: Icon(
                                                    _showClassement
                                                        ? Icons.visibility_off
                                                        : Icons.leaderboard,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    _showClassement
                                                        ? l.hideClassement
                                                        : l.showClassement,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        _showClassement
                                                        ? cs.tertiary
                                                        : cs.primary,
                                                    foregroundColor:
                                                        _showClassement
                                                        ? cs.onTertiary
                                                        : cs.onPrimary,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _showClassement =
                                                        !_showClassement,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${filtered.length} ${l.students}',
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
                                  SizedBox(height: 10),
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.filter_alt,
                                              size: 18,
                                              color: cs.primary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              l.filterBy,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_taadiaCategories.isNotEmpty) ...[
                                          SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 16,
                                                color: cs.onSurfaceVariant,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                l.selectCategory,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              ..._taadiaCategories.map((cat) {
                                                final selected = _categoryFilter.contains(cat);
                                                return FilterChip(
                                                  label: Text(cat, style: TextStyle(fontSize: 12)),
                                                  selected: selected,
                                                  selectedColor: cs.secondary.withValues(alpha: 0.2),
                                                  checkmarkColor: cs.secondary,
                                                  onSelected: (val) {
                                                    setState(() {
                                                      if (val) {
                                                        _categoryFilter.add(cat);
                                                      } else {
                                                        _categoryFilter.remove(cat);
                                                      }
                                                    });
                                                  },
                                                );
                                              }),
                                        ],
                                      ),
                                    ],
                                  if (_taadiaClassifications.isNotEmpty) ...[
                                        SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star_outline,
                                              size: 16,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              isRtl ? 'التصنيف' : 'Classification',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: cs.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        if (_taadiaClassifications.isNotEmpty)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: _taadiaClassifications.map((cfg) {
                                              final current = _classificationFilters[cfg.name];
                                              return Padding(
                                                padding: EdgeInsets.only(bottom: 6),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${cfg.name}: ',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: cs.onSurfaceVariant,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Wrap(
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children: [
                                                        ChoiceChip(
                                                          label: Text(l.all, style: TextStyle(fontSize: 12)),
                                                          selected: current == null,
                                                          onSelected: (_) {
                                                            setState(() {
                                                              _classificationFilters.remove(cfg.name);
                                                            });
                                                          },
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                        ...cfg.options.map((opt) {
                                                          return ChoiceChip(
                                                            label: Text(opt, style: TextStyle(fontSize: 12)),
                                                            selected: current == opt,
                                                            onSelected: (_) {
                                                              setState(() {
                                                                _classificationFilters[cfg.name] = opt;
                                                              });
                                                            },
                                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                            visualDensity: VisualDensity.compact,
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                  SizedBox(height: 8),
                                ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _studentSliverList(ranked),
                    SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _selectionChip(String label, String value, String current, ValueChanged<String> onChanged) {
    final cs = Theme.of(context).colorScheme;
    final selected = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.secondary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.secondary
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onSecondary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentSliverList(List<Evaluation> evals) {
    final showRank = widget.taadia.isPrivate || _showClassement;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildStudentCard(
            evals[index],
            rank: showRank ? index + 1 : null,
          );
        }, childCount: evals.length),
      ),
    );
  }

  Widget _buildStudentCard(Evaluation eval, {int? rank}) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final result = (widget.taadia.isPrivate || _showClassement) ? _calcResult(eval) : null;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
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
                .loadEvaluations(widget.taadia.id);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (rank != null)
                    Container(
                      width: 32,
                      height: 32,
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? [
                                Colors.amber,
                                Colors.grey,
                                Colors.brown,
                              ][rank - 1].withValues(alpha: 0.2)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: rank <= 3
                                ? [
                                    Colors.amber.shade700,
                                    Colors.grey.shade600,
                                    Colors.brown.shade500,
                                  ][rank - 1]
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Text(
                      eval.studentName.isNotEmpty
                          ? eval.studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                eval.studentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.taadia.isPrivate || _showClassement) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  result! % 1 == 0
                                      ? '${result.toInt()}'
                                      : result.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: cs.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                eval.evaluatorName.isNotEmpty
                                    ? eval.evaluatorName
                                    : l.unknown,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _miniChip(Icons.quiz_outlined, '${eval.numQuestions}', cs.secondary, cs),
                  if (_taadiaCategories.isNotEmpty && eval.categories.isNotEmpty)
                    ...eval.categories.map((cat) => _miniChip(Icons.category_outlined, cat, cs.primary, cs)),
                  if (widget.taadia.classifications.isNotEmpty)
                    ...widget.taadia.classifications.map((cfg) {
                      final val = eval.classificationValues[cfg.name];
                      if (val == null || val.isEmpty) return SizedBox.shrink();
                      return _miniChip(Icons.star_outline, val, cs.primary, cs);
                    }),
                  _miniChip(
                    Icons.menu_book_outlined,
                    eval.specialAhzab.isNotEmpty ? eval.specialAhzab : '${eval.numAhzab}',
                    cs.tertiary, cs,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(6),
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
                        icon: Icon(Icons.download, size: 18, color: cs.primary),
                        tooltip: 'Download PDF',
                        onPressed: () async {
                          try {
                            final l = AppLocalizations.of(context)!;
                            await PdfService.downloadSingleEvaluationPdf(
                              eval,
                              l,
                              formula: _showClassement ? _currentFormula : null,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('PDF downloaded'),
                                  backgroundColor: cs.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: cs.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        color: cs.outlineVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              if (eval.note.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
                      SizedBox(width: 6),
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
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 4),
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
          SizedBox(height: 2),
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
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    widget.analytics.logEvent(
      name: 'admin_download_taadia_pdf',
      parameters: {
        'taadia_id': widget.taadia.id,
        'taadia_title': widget.taadia.title,
      },
    );
    final cs = Theme.of(context).colorScheme;
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    final allEvals = await evalService.getEvaluationsOnce(widget.taadia.id);
    final evals = _filter(allEvals);

    if (evals.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allEvals.isEmpty
                  ? 'No evaluations yet'
                  : 'No evaluations match the current filter',
            ),
            backgroundColor: cs.error,
          ),
        );
      }
      return;
    }

    try {
      final l = AppLocalizations.of(context)!;
      await PdfService.downloadTaadiaPdf(
        widget.taadia,
        evals,
        l,
        formula: _showClassement ? _currentFormula : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded'),
            backgroundColor: cs.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }
}
