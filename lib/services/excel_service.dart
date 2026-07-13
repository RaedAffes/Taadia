import 'package:excel/excel.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/services/file_downloader.dart';

double _score(Evaluation e, String? formula) {
  if (formula == null) return 0;
  final x = e.questions.length;
  if (x == 0) return 0;
  final y = formula == 'jihawiya' ? 20.0 / x : 10.0 / x;
  double m = 0;
  for (final q in e.questions) m += 0.25 * q.ichaarat + 1.0 * q.taalakin;
  return 20 - y * m;
}

class ExcelService {
  static Future<void> downloadTaadiaExcel(
    Taadia taadia,
    List<Evaluation> evals,
    AppLocalizations l, {
    String? formula,
  }) async {
    final r = l.localeName == 'ar';
    final f = formula ?? taadia.formula;

    final excel = Excel.createExcel();
    final sheet = excel['تقرير'];

    final headers = r
        ? ['الترتيب', 'الاسم', 'نطاق الأحزاب', 'الإشعارات', 'التلقين', 'العلامة']
        : ['Rank', 'Name', 'Ahzab Range', 'Ichaarat', 'Taalakin', 'Score'];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }

    final scores = <String, double>{};
    for (final e in evals) scores[e.id] = _score(e, f);
    final sorted = List<Evaluation>.from(evals)
      ..sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));

    final ranks = <int>[1];
    for (var i = 1; i < sorted.length; i++) {
      ranks.add(scores[sorted[i].id]! != scores[sorted[i - 1].id]!
          ? i + 1
          : ranks.last);
    }

    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final sc = scores[e.id]!;
      final mark = sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1);
      final rangeText = e.specialAhzab.isNotEmpty
          ? e.specialAhzab
          : '${l.ahzab} ${e.numAhzab}';
      sheet.appendRow([
        TextCellValue('${ranks[i]}'),
        TextCellValue(e.studentName),
        TextCellValue(rangeText),
        TextCellValue('${e.totalIchaarat}'),
        TextCellValue('${e.totalTaalakin}'),
        TextCellValue(mark),
      ]);
    }

    final filename = r
        ? '${taadia.title}_تقرير.xlsx'
        : '${taadia.title}_Report.xlsx';
    await downloadFile(excel.save()!, filename);
  }

  static Future<void> downloadSingleEvaluationExcel(
    Evaluation eval,
    AppLocalizations l, {
    String? formula,
  }) async {
    final r = l.localeName == 'ar';
    final sc = formula != null ? _score(eval, formula) : null;
    final ahz = eval.specialAhzab.isNotEmpty
        ? eval.specialAhzab
        : (eval.numAhzab > 0 ? '${eval.numAhzab}' : '');

    final excel = Excel.createExcel();
    final sheet = excel[r ? 'تقييم' : 'Evaluation'];

    if (r) {
      sheet.appendRow([TextCellValue('الحقل'), TextCellValue('القيمة')]);
      sheet.appendRow([TextCellValue('اسم الطالب'), TextCellValue(eval.studentName)]);
      if (eval.evaluatorName.isNotEmpty) sheet.appendRow([TextCellValue('العارض'), TextCellValue(eval.evaluatorName)]);
      if (eval.categories.isNotEmpty) sheet.appendRow([TextCellValue('التصنيف'), TextCellValue(eval.categories.join(', '))]);
      sheet.appendRow([TextCellValue('عدد الأسئلة'), TextCellValue('${eval.numQuestions}')]);
      if (ahz.isNotEmpty) sheet.appendRow([TextCellValue('الأحزاب'), TextCellValue(ahz)]);
      if (eval.note.isNotEmpty) sheet.appendRow([TextCellValue('ملاحظة'), TextCellValue(eval.note)]);
      sheet.appendRow([TextCellValue('الإشعارات'), TextCellValue('${eval.totalIchaarat}')]);
      sheet.appendRow([TextCellValue('التلقين'), TextCellValue('${eval.totalTaalakin}')]);
      if (sc != null) {
        sheet.appendRow([TextCellValue('العلامة'), TextCellValue(sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1))]);
      }
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue('رقم السؤال'), TextCellValue('ملاحظة'), TextCellValue('الإشعارات'), TextCellValue('التلقين')]);
    } else {
      sheet.appendRow([TextCellValue('Field'), TextCellValue('Value')]);
      sheet.appendRow([TextCellValue('Student Name'), TextCellValue(eval.studentName)]);
      if (eval.evaluatorName.isNotEmpty) sheet.appendRow([TextCellValue('Evaluator'), TextCellValue(eval.evaluatorName)]);
      if (eval.categories.isNotEmpty) sheet.appendRow([TextCellValue('Category'), TextCellValue(eval.categories.join(', '))]);
      sheet.appendRow([TextCellValue('Questions'), TextCellValue('${eval.numQuestions}')]);
      if (ahz.isNotEmpty) sheet.appendRow([TextCellValue('Ahzab'), TextCellValue(ahz)]);
      if (eval.note.isNotEmpty) sheet.appendRow([TextCellValue('Note'), TextCellValue(eval.note)]);
      sheet.appendRow([TextCellValue('Ichaarat'), TextCellValue('${eval.totalIchaarat}')]);
      sheet.appendRow([TextCellValue('Taalakin'), TextCellValue('${eval.totalTaalakin}')]);
      if (sc != null) {
        sheet.appendRow([TextCellValue('Score'), TextCellValue(sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1))]);
      }
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue('Question Number'), TextCellValue('Note'), TextCellValue('Ichaarat'), TextCellValue('Taalakin')]);
    }

    for (final q in eval.questions) {
      var ic = 0;
      var tc = 0;
      for (int i = 0; i < q.tSetCount; i++) {
        final t1 = q.topCubes[i * 2];
        final t2 = q.topCubes[i * 2 + 1];
        final b = q.bottomCubes[i];
        if (b && (t1 || t2)) {
          tc++;
        } else {
          if (t1) ic++;
          if (t2) ic++;
        }
      }
      sheet.appendRow([TextCellValue('${q.number}'), TextCellValue(q.note), TextCellValue('$ic'), TextCellValue('$tc')]);
    }

    final filename = r ? 'تقييم_${eval.studentName}.xlsx' : '${eval.studentName}.xlsx';
    await downloadFile(excel.save()!, filename);
  }
}
