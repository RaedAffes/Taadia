import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/formula_config.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class PrivateTaadiasListScreen extends StatefulWidget {
  @override
  _PrivateTaadiasListScreenState createState() =>
      _PrivateTaadiasListScreenState();
}

class _PrivateTaadiasListScreenState extends State<PrivateTaadiasListScreen> {
  String? _currentTaadiaId;
  StreamSubscription? _evalSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCurrentTaadia();
    });
  }

  @override
  void dispose() {
    _evalSub?.cancel();
    super.dispose();
  }

  Future<void> _initCurrentTaadia() async {
    final taadiaService = Provider.of<TaadiaService>(context, listen: false);
    await taadiaService.loadUserPrivateTaadias();
    final taadias = taadiaService.userPrivateTaadias;
    if (taadias.isNotEmpty) {
      _selectTaadia(taadias.first.id);
    }
  }

  void _selectTaadia(String id) {
    setState(() {
      _currentTaadiaId = id;
    });
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    _evalSub?.cancel();
    evalService.loadEvaluations(id);
  }

  double _calcResult(Evaluation e) {
    final x = e.questions.length;
    if (x == 0) return 0;
    final formula = e.formula;
    final y = formula == 'jihawiya' ? 20.0 / x : 10.0 / x;
    double m = 0;
    for (final q in e.questions) {
      m += 0.25 * q.ichaarat + 1.0 * q.taalakin;
    }
    return 20 - y * m;
  }

  String _formulaLabel(String f, AppLocalizations l) {
    return FormulaConfig.fromJson(
      f,
    ).displayLabel(l.totalIchaarat, l.totalTaalakin);
  }

  Future<void> _showFormulaForEval(Evaluation e) async {
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
              'محلية',
              Icons.location_city,
              cs.primary,
              e.formula,
            ),
            SizedBox(height: 8),
            _formulaOption(
              ctx,
              'jihawiya',
              'جهوية',
              Icons.public,
              cs.secondary,
              e.formula,
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

    if (result != null && result != e.formula && mounted) {
      final svc = Provider.of<EvaluationService>(context, listen: false);
      await svc.updateFormula(e.id, result);
    }
  }

  Widget _formulaOption(
    BuildContext ctx,
    String value,
    String label,
    IconData icon,
    Color color,
    String currentFormula,
  ) {
    final selected = currentFormula == value;
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final taadiaService = context.watch<TaadiaService>();
    final evalService = context.watch<EvaluationService>();

    final myPrivateTaadias = taadiaService.userPrivateTaadias;
    final evals = evalService.evaluations;

    return AppScaffold(
      title: l.myPrivateTaadias,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ts = Provider.of<TaadiaService>(context, listen: false);
          String taadiaId;
          if (_currentTaadiaId != null) {
            taadiaId = _currentTaadiaId!;
          } else {
            final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
            final tempTaadia = Taadia(
              id: offlineId,
              title: 'تقييم ${DateTime.now().toString().substring(0, 16)}',
              createdBy: '',
              createdAt: DateTime.now(),
            );
            setState(() => _currentTaadiaId = offlineId);
            taadiaId = offlineId;
            // Create in background without blocking navigation
            ts.createPrivateTaadia(
              'تقييم ${DateTime.now().toString().substring(0, 16)}',
            ).then((realId) {
              if (realId != null && mounted && _currentTaadiaId == offlineId) {
                setState(() => _currentTaadiaId = realId);
              }
            });
          }
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EvaluateScreen(taadiaId: taadiaId, taadiaTitle: ''),
              ),
            );
            if (mounted) {
              final es = Provider.of<EvaluationService>(context, listen: false);
              es.loadEvaluations(taadiaId);
            }
          }
        },
        child: Icon(Icons.add),
        tooltip: l.evaluate,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final ts = Provider.of<TaadiaService>(context, listen: false);
          await ts.loadUserPrivateTaadias();
          final taadias = ts.userPrivateTaadias;
          if (taadias.isNotEmpty) {
            _selectTaadia(taadias.first.id);
          } else {
            setState(() => _currentTaadiaId = null);
          }
        },
        child: _currentTaadiaId == null && myPrivateTaadias.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 64,
                          color: cs.outlineVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l.noEvaluationsYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          l.tapToCreateFirst,
                          style: TextStyle(color: cs.outlineVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _currentTaadiaId == null || evalService.isLoading
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : evals.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 64,
                          color: cs.outlineVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l.noEvaluationsYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          l.tapToCreateFirst,
                          style: TextStyle(color: cs.outlineVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: evals.length,
                itemBuilder: (context, index) {
                  final e = evals[index];
                  final result = _calcResult(e);
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    color: cs.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EvaluateScreen(
                              taadiaId: _currentTaadiaId!,
                              taadiaTitle: '',
                              editingEvaluation: e,
                            ),
                          ),
                        ).then((_) {
                          if (_currentTaadiaId != null) {
                            Provider.of<EvaluationService>(
                              context,
                              listen: false,
                            ).loadEvaluations(_currentTaadiaId!);
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  child: Text(
                                    e.studentName.isNotEmpty
                                        ? e.studentName[0].toUpperCase()
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              e.studentName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: cs.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    _showFormulaForEval(e),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: cs.tertiaryContainer
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: cs.tertiary
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.swap_horiz,
                                                        size: 13,
                                                        color: cs.tertiary,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        _formulaLabel(
                                                          e.formula,
                                                          l,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: cs.tertiary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              result % 1 == 0
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
                                              e.evaluatorName.isNotEmpty
                                                  ? e.evaluatorName
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
                                _miniChip(
                                  Icons.quiz_outlined,
                                  '${e.numQuestions}',
                                  cs.secondary,
                                  cs,
                                ),
                                _miniChip(
                                  Icons.menu_book_outlined,
                                  e.specialAhzab.isNotEmpty
                                      ? e.specialAhzab
                                      : '${e.numAhzab}',
                                  cs.tertiary,
                                  cs,
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
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _scoreBlock(
                                      Icons.notifications,
                                      l.totalIchaarat,
                                      '${e.totalIchaarat}',
                                      cs.primary,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  Expanded(
                                    child: _scoreBlock(
                                      Icons.record_voice_over,
                                      l.totalTaalakin,
                                      '${e.totalTaalakin}',
                                      cs.secondary,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.download,
                                        size: 18,
                                        color: cs.primary,
                                      ),
                                      tooltip: 'Download PDF',
                                      onPressed: () async {
                                        try {
                                          await PdfService.downloadSingleEvaluationPdf(
                                            e,
                                            l,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('PDF downloaded'),
                                                backgroundColor: cs.primary,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: cs.outlineVariant,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (e.note.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.notes,
                                      size: 16,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        e.note,
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
                },
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
