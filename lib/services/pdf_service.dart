import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'pdf_downloader.dart';

const _pri = PdfColor.fromInt(0xFF8B7D6B);
const _sec = PdfColor.fromInt(0xFFA0937D);
const _txtC = PdfColor.fromInt(0xFF3E3A36);
const _muted = PdfColor.fromInt(0xFF9E948A);
const _bdr = PdfColor.fromInt(0xFFE8E3DD);
const _wht = PdfColors.white;

pw.Font? _amiri;

Future<pw.Font> _font() async {
  if (_amiri != null) return _amiri!;
  try {
    _amiri = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri.ttf'));
    return _amiri!;
  } catch (_) {
    return pw.Font.helvetica();
  }
}

pw.TextStyle _ts(double s, PdfColor c, {bool b = false}) => pw.TextStyle(
  fontSize: s,
  color: c,
  fontWeight: b ? pw.FontWeight.bold : pw.FontWeight.normal,
);

bool _hasAr(String s) => s.runes.any(
  (r) => r >= 0x0600 && r <= 0x06FF || r >= 0xFB50 && r <= 0xFDFF,
);

pw.TextDirection _dir(String t) =>
    _hasAr(t) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

pw.Widget _tx(String t, double s, PdfColor c, bool b, bool r) => pw.Text(
  t,
  style: _ts(s, c, b: b),
  textDirection: _dir(t),
);

pw.Widget _bl(String t, PdfColor c, bool r) => pw.Container(
  padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: pw.BoxDecoration(
    color: c,
    borderRadius: pw.BorderRadius.circular(6),
  ),
  child: pw.Text(t, style: _ts(15, _wht, b: true), textDirection: _dir(t)),
);

pw.Widget _tag(String t, PdfColor c, bool r) => pw.Container(
  padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: pw.BoxDecoration(
    color: c,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(t, style: _ts(13, _wht, b: true), textDirection: _dir(t)),
);

double _score(Evaluation e, String f) {
  final x = e.questions.length;
  if (x == 0) return 0;
  final y = f == 'jihawiya' ? 20.0 / x : 10.0 / x;
  double m = 0;
  for (final q in e.questions) m += 0.25 * q.ichaarat + 1.0 * q.taalakin;
  return 20 - y * m;
}

class PdfService {
  static Future<void> downloadTaadiaPdf(
    Taadia taadia,
    List<Evaluation> evals,
    AppLocalizations l, {
    String? formula,
  }) async {
    final f = await _font();
    final r = l.localeName == 'ar';
    final formulaStr = formula ?? taadia.formula;
    final scores = <String, double>{};
    for (final e in evals) scores[e.id] = _score(e, formulaStr);
    final sorted = List<Evaluation>.from(evals)
      ..sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));

    const tableFont = 16.0;
    const headerColor = _pri;
    const evenColor = PdfColor.fromInt(0xFFF8F6F3);
    const oddColor = PdfColors.white;
    const padV = 4.0;
    const padVHead = 6.0;
    const cwR = 60.0, cwM = 60.0, cGap = 8.0;
    const pageW = 547.0;
    final cwN = pageW - cwR - cwM - 2 * cGap;
    final rowW = pageW;

    pw.Widget _tc(String t, PdfColor c, double pv, {bool center = false}) => pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: pv),
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        t,
        style: pw.TextStyle(fontSize: tableFont, color: c, fontWeight: pw.FontWeight.bold),
        textDirection: _dir(t),
      ),
    );

    final doc = pw.Document();
    final rows = <pw.Widget>[
      pw.Container(
        width: rowW,
        decoration: pw.BoxDecoration(color: headerColor),
        child: pw.Row(
          children: [
            pw.Container(width: cwR, child: _tc(r ? '#' : 'Rank', _wht, padVHead, center: true)),
            pw.Container(width: cwN, child: _tc(l.name, _wht, padVHead)),
            pw.Container(width: cwM, child: _tc(r ? 'الدرجة' : 'Mark', _wht, padVHead, center: true)),
          ],
        ),
      ),
    ];
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final sc = scores[e.id]!;
      final mark = sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1);
      rows.add(
        pw.Container(
          width: rowW,
          decoration: pw.BoxDecoration(
            color: i.isEven ? evenColor : oddColor,
            border: pw.Border(bottom: pw.BorderSide(color: _bdr, width: 0.5)),
          ),
          child: pw.Row(
            children: [
              pw.Container(width: cwR, child: _tc('${i + 1}', _txtC, padV, center: true)),
              pw.Container(width: cwN, child: _tc(e.studentName, _txtC, padV)),
              pw.Container(width: cwM, child: _tc(mark, _pri, padV, center: true)),
            ],
          ),
        ),
      );
    }
    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: f, bold: f),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: _tx(taadia.title, 30, _pri, true, r),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(thickness: 0.5, color: _bdr),
            pw.SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
    final n = r ? 'تقرير_${taadia.title}.pdf' : '${taadia.title}_Report.pdf';
    await downloadPdf(await doc.save(), n);
  }

  static Future<void> downloadSingleEvaluationPdf(
    Evaluation eval,
    AppLocalizations l, {
    String? formula,
  }) async {
    final f = await _font();
    final r = l.localeName == 'ar';
    final sc = formula != null ? _score(eval, formula) : null;
    final ahz = eval.specialAhzab.isNotEmpty
        ? eval.specialAhzab
        : (eval.numAhzab > 0 ? '${eval.numAhzab}' : '');
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: f, bold: f),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(eval, sc, ahz, r, l),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 0.5, color: _bdr),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _bl(
                  '${l.ichaarat}: ${eval.totalIchaarat}  |  ${l.taalakin}: ${eval.totalTaalakin}',
                  _pri,
                  r,
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            ...eval.questions.map((q) => _qcard(q, r, l)),
          ],
        ),
      ),
    );
    final n = r ? 'تقييم_${eval.studentName}.pdf' : '${eval.studentName}.pdf';
    await downloadPdf(await doc.save(), n);
  }

  static pw.Widget _header(
    Evaluation e,
    double? sc,
    String ahz,
    bool r,
    AppLocalizations l,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _wht,
        border: pw.Border.all(color: _bdr),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _tx(e.studentName, 30, _pri, true, r),
              pw.Spacer(),
              if (sc != null)
                _bl(
                  sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1),
                  _pri,
                  r,
                ),
            ],
          ),
          pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                if (e.evaluatorName.isNotEmpty)
                  _tx('${l.evaluator}: ${e.evaluatorName}', 14, _txtC, true, r),
                if (e.categories.isNotEmpty)
                  _tx('${l.selectCategory}: ${e.categories.join(', ')}', 14, _txtC, true, r),
                _tx('${l.questions}: ${e.numQuestions}', 14, _txtC, true, r),
                if (ahz.isNotEmpty) _tx('${l.ahzab}: $ahz', 14, _txtC, true, r),
              ],
            ),
          if (e.note.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _tx(e.note, 14, _muted, true, r),
          ],
        ],
      ),
    );
  }

  static pw.Widget _qcard(QuestionItem q, bool r, AppLocalizations l) {
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
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12),
      padding: pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _wht,
        border: pw.Border.all(color: _bdr),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _tx('${l.qPrefix}${q.number}', 18, _pri, true, r),
              pw.Spacer(),
              if (q.note.isNotEmpty) _tx(q.note, 13, _muted, true, r),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _tag('${l.ichaarat}: $ic', _pri, r),
              pw.SizedBox(width: 12),
              _tag('${l.taalakin}: $tc', _sec, r),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 12,
            runSpacing: 10,
            children: List.generate(
              q.tSetCount,
              (i) => _tset(
                q.topCubes[i * 2],
                q.topCubes[i * 2 + 1],
                q.bottomCubes[i],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tset(bool t1, bool t2, bool b) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [_cube(t1, _pri), pw.SizedBox(width: 4), _cube(t2, _pri)],
        ),
        pw.SizedBox(height: 4),
        _cube(b, _sec),
      ],
    );
  }

  static pw.Widget _cube(bool filled, PdfColor ac) {
    final bg = filled ? PdfColor.fromInt(0xFFF5F0EB) : _wht;
    return pw.Container(
      width: 30,
      height: 30,
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: filled ? ac : _bdr, width: filled ? 3 : 1.5),
      ),
      child: filled
          ? pw.Center(
              child: pw.Text(
                '✕',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: ac,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          : pw.SizedBox(),
    );
  }
}
