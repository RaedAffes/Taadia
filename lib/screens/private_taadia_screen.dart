import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class PrivateTaadiaScreen extends StatefulWidget {
  final String taadiaId;
  final String taadiaTitle;
  final String taadiaDescription;

  PrivateTaadiaScreen({
    required this.taadiaId,
    required this.taadiaTitle,
    this.taadiaDescription = '',
  });

  @override
  _PrivateTaadiaScreenState createState() => _PrivateTaadiaScreenState();
}

class _PrivateTaadiaScreenState extends State<PrivateTaadiaScreen> {
  Taadia? _taadia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EvaluationService>(
        context,
        listen: false,
      ).loadEvaluations(widget.taadiaId);
      _refreshTaadia();
    });
  }

  Future<void> _refreshTaadia() async {
    final svc = Provider.of<TaadiaService>(context, listen: false);
    final t = svc.userPrivateTaadias.where((t) => t.id == widget.taadiaId).firstOrNull;
    if (t != null) {
      setState(() {
        _taadia = t;
      });
    }
  }

  Future<void> _downloadPdf() async {
    final cs = Theme.of(context).colorScheme;
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    final allEvals = await evalService.getEvaluationsOnce(widget.taadiaId);

    if (allEvals.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No evaluations yet'),
            backgroundColor: cs.error,
          ),
        );
      }
      return;
    }

    final t = _taadia ?? Taadia(
      id: widget.taadiaId,
      title: widget.taadiaTitle,
      createdBy: '',
      createdAt: DateTime.now(),
      formula: 'mahalia',
      visibility: 'private',
    );

    try {
      final l = AppLocalizations.of(context)!;
      await PdfService.downloadTaadiaPdf(t, allEvals, l);
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

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
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
    if (confirmed == true && mounted) {
      final svc = Provider.of<TaadiaService>(context, listen: false);
      final ok = await svc.deleteTaadia(widget.taadiaId);
      if (ok && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToEvaluate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluateScreen(
          taadiaId: widget.taadiaId,
          taadiaTitle: widget.taadiaTitle,
          classifications: _taadia?.classifications ?? [],
        ),
      ),
    ).then((_) {
      Provider.of<EvaluationService>(context, listen: false)
          .loadEvaluations(widget.taadiaId);
      _refreshTaadia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final evalService = Provider.of<EvaluationService>(context);

    return AppScaffold(
      title: widget.taadiaTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEvaluate,
        child: Icon(Icons.add),
        tooltip: l.evaluate,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.rate_review),
          tooltip: l.evaluate,
          onPressed: _navigateToEvaluate,
        ),
        IconButton(
          icon: Icon(Icons.download),
          tooltip: 'Download PDF',
          onPressed: _downloadPdf,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline),
          tooltip: l.deleteEvaluation,
          onPressed: _confirmDelete,
        ),
      ],
      body: evalService.isLoading
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
                    l.noEvaluationsYet,
                    style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l.tapToCreateFirst,
                    style: TextStyle(color: cs.outlineVariant),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => evalService.loadEvaluations(widget.taadiaId),
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: evalService.evaluations.length,
                itemBuilder: (context, index) {
                  final e = evalService.evaluations[index];
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.studentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: cs.onSurface,
                                      ),
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
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: cs.primary,
                                ),
                                tooltip: 'Edit',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EvaluateScreen(
                                        taadiaId: widget.taadiaId,
                                        taadiaTitle: widget.taadiaTitle,
                                        classifications: _taadia?.classifications ?? [],
                                        editingEvaluation: e,
                                      ),
                                    ),
                                  ).then((_) {
                                    Provider.of<EvaluationService>(
                                      context, listen: false,
                                    ).loadEvaluations(widget.taadiaId);
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.download,
                                  size: 20,
                                  color: cs.primary,
                                ),
                                tooltip: 'Download PDF',
                                onPressed: () async {
                                  try {
                                    final l = AppLocalizations.of(context)!;
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
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: _tag(
                              '#${index + 1}',
                              cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _tag(String text, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

}
