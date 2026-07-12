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

class CsvService {
  static void downloadTaadiaCsv(
    Taadia taadia,
    List<Evaluation> evals,
    AppLocalizations l, {
    String? formula,
  }) {
    final r = l.localeName == 'ar';
    final f = formula ?? taadia.formula;

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    if (r) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
          TextCellValue('الترتيب');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
          TextCellValue('الاسم');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
          TextCellValue('نطاق الأحزاب');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
          TextCellValue('الإشعارات');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value =
          TextCellValue('التلقين');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value =
          TextCellValue('العلامة');
    } else {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
          TextCellValue('Rank');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
          TextCellValue('Name');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
          TextCellValue('Ahzab Range');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
          TextCellValue('Ichaarat');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value =
          TextCellValue('Taalakin');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value =
          TextCellValue('Score');
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
      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('${ranks[i]}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(e.studentName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue(rangeText);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          TextCellValue('${e.totalIchaarat}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          TextCellValue('${e.totalTaalakin}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          TextCellValue(mark);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final filename = r
        ? '${taadia.title}.xlsx'
        : '${taadia.title}_Report.xlsx';
    downloadFile(bytes, filename);
  }

  static void downloadSingleEvaluationCsv(
    Evaluation eval,
    AppLocalizations l, {
    String? formula,
  }) {
    final r = l.localeName == 'ar';
    final sc = formula != null ? _score(eval, formula) : null;
    final ahz = eval.specialAhzab.isNotEmpty
        ? eval.specialAhzab
        : (eval.numAhzab > 0 ? '${eval.numAhzab}' : '');

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    int row = 0;
    if (r) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('الحقل');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('القيمة');
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('اسم الطالب');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(eval.studentName);
      row++;
      if (eval.evaluatorName.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('العارض');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.evaluatorName);
        row++;
      }
      if (eval.categories.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('التصنيف');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.categories.join(', '));
        row++;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('عدد الأسئلة');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.numQuestions}');
      row++;
      if (ahz.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('الأحزاب');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(ahz);
        row++;
      }
      if (eval.note.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('ملاحظة');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.note);
        row++;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('الإشعارات');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.totalIchaarat}');
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('التلقين');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.totalTaalakin}');
      row++;
      if (sc != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('العلامة');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(
            sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1));
        row++;
      }
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('رقم السؤال');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('ملاحظة');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue('الإشعارات');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          TextCellValue('التلقين');
    } else {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Field');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('Value');
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Student Name');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(eval.studentName);
      row++;
      if (eval.evaluatorName.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('Evaluator');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.evaluatorName);
        row++;
      }
      if (eval.categories.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('Category');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.categories.join(', '));
        row++;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Questions');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.numQuestions}');
      row++;
      if (ahz.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('Ahzab');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(ahz);
        row++;
      }
      if (eval.note.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('Note');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(eval.note);
        row++;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Ichaarat');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.totalIchaarat}');
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Taalakin');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('${eval.totalTaalakin}');
      row++;
      if (sc != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue('Score');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(
            sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1));
        row++;
      }
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('Question Number');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue('Note');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue('Ichaarat');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          TextCellValue('Taalakin');
    }
    row++;

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
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('${q.number}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(q.note);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue('$ic');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          TextCellValue('$tc');
      row++;
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final filename =
        r ? 'تقييم_${eval.studentName}.xlsx' : '${eval.studentName}.xlsx';
    downloadFile(bytes, filename);
  }
}
