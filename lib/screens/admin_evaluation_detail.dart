import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/services/csv_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/download_choice_dialog.dart';
import 'package:ta3dia/ai/ai_service.dart';

class _RangeCriterionDisplay {
  final String label;

  _RangeCriterionDisplay._(this.label);

  static String _hizbLabel(int? from, int? to) {
    if (from == null) return '';
    if (to == null || to == from) return 'الحزب $from';
    if (to - from == 1) return 'أحزاب $from-$to';
    return 'من الحزب $from إلى $to';
  }

  static String _surahLabel(int? from, int? to) {
    if (from == null) return '';
    final fromName = AiService.surahNameAr(from) ?? 'السورة $from';
    if (to == null || to == from) return 'سورة $fromName';
    final toName = AiService.surahNameAr(to) ?? 'السورة $to';
    if (to - from == 1) return 'سور $fromName - $toName';
    return 'من سورة $fromName إلى سورة $toName';
  }

  factory _RangeCriterionDisplay.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as int;
    final parts = <String>[];
    switch (QuestionRangeType.values[type]) {
      case QuestionRangeType.allQuran:
        return _RangeCriterionDisplay._('كامل القرآن');
      case QuestionRangeType.hizbRange:
        final hFrom = map['hizbFrom'] as int?;
        final hTo = map['hizbTo'] as int?;
        if (hFrom != null) parts.add(_hizbLabel(hFrom, hTo));
        for (final r in (map['hizbSubRanges'] as List?) ?? []) {
          final l = (r as List).cast<dynamic>();
          final subLabel = _hizbLabel(l[0] as int?, l[1] as int?);
          if (subLabel.isNotEmpty) parts.add(subLabel);
        }
        return _RangeCriterionDisplay._(parts.isEmpty ? '' : parts.join(' + '));
      case QuestionRangeType.surahs:
        final sFrom = map['surahFrom'] as int?;
        final sTo = map['surahTo'] as int?;
        if (sFrom != null) parts.add(_surahLabel(sFrom, sTo));
        for (final r in (map['surahSubRanges'] as List?) ?? []) {
          final l = (r as List).cast<dynamic>();
          final subLabel = _surahLabel(l[0] as int?, l[1] as int?);
          if (subLabel.isNotEmpty) parts.add(subLabel);
        }
        return _RangeCriterionDisplay._(parts.isEmpty ? '' : parts.join(' + '));
      case QuestionRangeType.surahAyahRange:
        for (final r in (map['surahAyahSubRanges'] as List?) ?? []) {
          final l = (r as List).cast<dynamic>();
          final suraNo = l[0] as int?;
          final aFrom = l[1] as int?;
          final aTo = l[2] as int?;
          if (suraNo != null && aFrom != null) {
            final name = AiService.surahNameAr(suraNo) ?? 'السورة $suraNo';
            final range = aTo != null && aTo != aFrom ? '$aFrom-$aTo' : '$aFrom';
            parts.add('آيات من سورة $name ($range)');
          }
        }
        if (parts.isEmpty) {
          final nums = map['surahNumbers'] as List? ?? [];
          final aFrom = map['ayaFrom'] as int?;
          final aTo = map['ayaTo'] as int?;
          if (nums.isNotEmpty && aFrom != null) {
            final name = AiService.surahNameAr(nums.first as int) ?? 'السورة ${nums.first}';
            final range = aTo != null && aTo != aFrom ? '$aFrom-$aTo' : '$aFrom';
            parts.add('آيات من سورة $name ($range)');
          }
        }
        return _RangeCriterionDisplay._(parts.isEmpty ? '' : parts.join(' + '));
      case QuestionRangeType.surahPages:
        for (final r in (map['surahPageSubRanges'] as List?) ?? []) {
          final l = (r as List).cast<dynamic>();
          final suraNo = l[0] as int?;
          final pFrom = l[1] as int?;
          final pTo = l[2] as int?;
          if (suraNo != null && pFrom != null) {
            final name = AiService.surahNameAr(suraNo) ?? 'السورة $suraNo';
            final range = pTo != null && pTo != pFrom ? '$pFrom-$pTo' : '$pFrom';
            parts.add('صفحات من سورة $name ($range)');
          }
        }
        if (parts.isEmpty) {
          final nums = map['surahNumbers'] as List? ?? [];
          final pFrom = map['pageFrom'] as int?;
          final pTo = map['pageTo'] as int?;
          if (nums.isNotEmpty && pFrom != null) {
            final name = AiService.surahNameAr(nums.first as int) ?? 'السورة ${nums.first}';
            final range = pTo != null && pTo != pFrom ? '$pFrom-$pTo' : '$pFrom';
            parts.add('صفحات من سورة $name ($range)');
          }
        }
        return _RangeCriterionDisplay._(parts.isEmpty ? '' : parts.join(' + '));
      case QuestionRangeType.quarter:
        final qs = (map['quarterNumbers'] as List?)?.cast<int>() ?? <int>[];
        const labels = ['الأول', 'الثاني', 'الثالث', 'الرابع'];
        final selected = qs.map((q) => labels[q.clamp(1, 4) - 1]).join('، ');
        return _RangeCriterionDisplay._('الربع $selected');
    }
  }
}

class AdminEvaluationDetail extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Evaluation evaluation;

  AdminEvaluationDetail({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AppScaffold(
      title: evaluation.studentName,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.person, size: 32, color: cs.onPrimaryContainer),
                    ),
                    SizedBox(height: 12),
                    Text(
                      evaluation.studentName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (evaluation.categories.isNotEmpty)
                          ...evaluation.categories.map((cat) => _infoBadge(cat, Color(0xFF6B8B7D))),
                        if (evaluation.classificationValues.isNotEmpty)
                          ...evaluation.classificationValues.entries.map((entry) => _infoBadge(
                            '${entry.value}',
                            cs.primary,
                          )),
                        if (evaluation.rangeCriteria.isNotEmpty)
                          _infoBadge(
                            '${l.numberOfAhzab}: ${evaluation.rangeCriteria.length}',
                            Color(0xFF6B8B7D),
                          )
                        else if (evaluation.numAhzab > 0)
                          _infoBadge(
                            '${l.numberOfAhzab}: ${evaluation.numAhzab}',
                            Color(0xFF6B8B7D),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(color: cs.outlineVariant),
                    SizedBox(height: 12),
                    _infoRow(
                      Icons.person_outline,
                      l.evaluator,
                      evaluation.evaluatorName.isNotEmpty
                          ? evaluation.evaluatorName
                          : l.unknown,
                      cs,
                    ),
                    SizedBox(height: 8),
                    _infoRow(
                      Icons.quiz_outlined,
                      l.questions,
                      '${evaluation.numQuestions}',
                      cs,
                    ),
                    SizedBox(height: 8),
                    if (evaluation.rangeCriteria.isNotEmpty)
                      ...evaluation.rangeCriteria.map((rc) {
                        final c = _RangeCriterionDisplay.fromMap(rc);
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: _infoRow(
                            Icons.menu_book_outlined,
                            l.ahzab,
                            c.label,
                            cs,
                          ),
                        );
                      })
                    else
                      _infoRow(
                        Icons.menu_book_outlined,
                        l.ahzab,
                        evaluation.specialAhzab.isNotEmpty
                            ? evaluation.specialAhzab
                            : '${l.numberOfAhzab}: ${evaluation.numAhzab}',
                        cs,
                      ),
                    if (evaluation.note.isNotEmpty) ...[
                      SizedBox(height: 8),
                      _infoRow(Icons.notes, l.note, evaluation.note, cs),
                    ],
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withValues(alpha: 0.08),
                            cs.secondary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _summaryBox(
                              Icons.notifications,
                              l.totalIchaarat,
                              '${evaluation.totalIchaarat}',
                              cs.primary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: _summaryBox(
                              Icons.record_voice_over,
                              l.totalTaalakin,
                              '${evaluation.totalTaalakin}',
                              cs.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              l.questions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 12),
            ...List.generate(evaluation.questions.length, (i) {
              final q = evaluation.questions[i];
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withValues(alpha: 0.8),
                                cs.primary.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${q.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${l.question} ${q.number}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                        Spacer(),
                        if (q.note.isNotEmpty)
                          Icon(Icons.notes, size: 16, color: cs.outlineVariant),
                      ],
                    ),
                    if (q.note.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          q.note,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _scoreBadge(
                            Icons.notifications,
                            '${q.ichaarat}',
                            cs.primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _scoreBadge(
                            Icons.record_voice_over,
                            '${q.taalakin}',
                            cs.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.download, color: cs.primary),
                    label: Text(
                      'Download PDF',
                      style: TextStyle(color: cs.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      analytics.logEvent(
                        name: 'admin_download_evaluation_pdf',
                        parameters: {
                          'evaluation_id': evaluation.id,
                          'student_name': evaluation.studentName,
                        },
                      );
                      try {
                        final l = AppLocalizations.of(context)!;
                        await PdfService.downloadSingleEvaluationPdf(
                          evaluation,
                          l,
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
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      analytics.logEvent(
                        name: 'admin_delete_evaluation',
                        parameters: {
                          'evaluation_id': evaluation.id,
                          'student_name': evaluation.studentName,
                        },
                      );
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l.deleteEvaluation),
                          content: Text(
                            l.deleteEvalConfirm(evaluation.studentName),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<EvaluationService>(
                                  context,
                                  listen: false,
                                ).deleteEvaluation(evaluation.id);
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: Text(
                                l.delete,
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    label: Text(l.delete, style: TextStyle(color: cs.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _scoreBadge(IconData icon, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
