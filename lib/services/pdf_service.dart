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
  padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: pw.BoxDecoration(
    color: c,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(t, style: _ts(11, _wht, b: true), textDirection: _dir(t)),
);

pw.Widget _tag(String t, PdfColor c, bool r) => pw.Container(
  padding: pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  decoration: pw.BoxDecoration(
    color: c,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(t, style: _ts(10, _wht, b: true), textDirection: _dir(t)),
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
    Map<String, String>? classificationFilter,
  }) async {
    final f = await _font();
    final r = l.localeName == 'ar';
    final formulaStr = formula ?? taadia.formula;
    final scores = <String, double>{};
    for (final e in evals) scores[e.id] = _score(e, formulaStr);
    final sorted = List<Evaluation>.from(evals)
      ..sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));

    List<int> _calcRanks(List<Evaluation> items) {
      if (items.isEmpty) return [];
      final rs = <int>[1];
      for (var i = 1; i < items.length; i++) {
        rs.add(scores[items[i].id]! != scores[items[i - 1].id]! ? i + 1 : rs.last);
      }
      return rs;
    }

    const rowPf = 14.5;
    const headerColor = _pri;
    const evenColor = PdfColor.fromInt(0xFFF8F6F3);
    const oddColor = PdfColors.white;
    const margin = 17.0;
    final pageW = PdfPageFormat.a4.width - 2 * margin;
    final hasFilter = classificationFilter != null && classificationFilter.isNotEmpty;

    final overallRanks = _calcRanks(sorted);
    final rankMap = <String, int>{};
    for (var i = 0; i < sorted.length; i++) rankMap[sorted[i].id] = overallRanks[i];

    pw.Widget _buildGroup(List<Evaluation> items, List<int> rs, double availW) {
      const rowPf = 14.5;
      final cwR = 25.0, cwM = 39.0;
      final cwN = availW - cwR - cwM;
      return pw.Column(mainAxisAlignment: pw.MainAxisAlignment.start, crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Container(
          height: 25, width: availW,
          decoration: pw.BoxDecoration(color: headerColor),
          child: pw.Row(children: [
            pw.Container(width: cwR, alignment: pw.Alignment.center, child: pw.Text(r ? '#' : 'Rank', style: pw.TextStyle(fontSize: rowPf, color: _wht, fontWeight: pw.FontWeight.bold), textDirection: _dir('#'))),
            pw.Container(width: cwN, alignment: pw.Alignment.centerLeft, child: pw.Text(l.name, style: pw.TextStyle(fontSize: rowPf, color: _wht, fontWeight: pw.FontWeight.bold), textDirection: _dir(l.name))),
            pw.Container(width: cwM, alignment: pw.Alignment.center, child: pw.Text(formulaStr == 'jihawiya' ? 'جهوية' : 'محلية', style: pw.TextStyle(fontSize: rowPf, color: _wht, fontWeight: pw.FontWeight.bold), textDirection: _dir('جهوية'))),
          ]),
        ),
          ...List.generate(items.length, (i) {
          final e = items[i];
          final sc = scores[e.id]!;
          final mark = sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1);
          final rangeText = e.specialAhzab.isNotEmpty
              ? e.specialAhzab
              : '${l.ahzab} ${e.numAhzab}';
          return pw.Container(
            width: availW,
            decoration: pw.BoxDecoration(color: i.isEven ? evenColor : oddColor, border: pw.Border(bottom: pw.BorderSide(color: _bdr, width: 0.4))),
            child: pw.Row(children: [
              pw.Container(width: cwR, child: pw.Text('${rs[i]}', style: pw.TextStyle(fontSize: rowPf, color: _txtC, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.ltr, textAlign: pw.TextAlign.center)),
              pw.Container(width: cwN, padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text(e.studentName, style: pw.TextStyle(fontSize: rowPf, color: _txtC, fontWeight: pw.FontWeight.bold), textDirection: _dir(e.studentName)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(child: pw.Text('($rangeText)', style: pw.TextStyle(fontSize: 14, color: _muted, fontWeight: pw.FontWeight.bold), textDirection: _dir(rangeText))),
                  ]),
                  pw.SizedBox(height: 2),
                  pw.Row(children: [
                    pw.Text(e.totalIchaarat.toString(), style: pw.TextStyle(fontSize: rowPf, color: _pri, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.ltr),
                    pw.Text('${l.ichaarat} :', style: pw.TextStyle(fontSize: 14, color: _txtC, fontWeight: pw.FontWeight.bold), textDirection: _dir(l.ichaarat)),
                    pw.SizedBox(width: 14),
                    pw.Text(e.totalTaalakin.toString(), style: pw.TextStyle(fontSize: rowPf, color: _sec, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.ltr),
                    pw.Text('${l.taalakin} :', style: pw.TextStyle(fontSize: 14, color: _txtC, fontWeight: pw.FontWeight.bold), textDirection: _dir(l.taalakin)),
                  ]),
                ]),
              ),
              pw.Container(width: cwM, child: pw.Text(mark, style: pw.TextStyle(fontSize: rowPf, color: _pri, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.ltr, textAlign: pw.TextAlign.center)),
            ]),
          );
          }),
      ]);
    }

    final doc = pw.Document();
    final ranks = sorted.map((e) => rankMap[e.id]!).toList();
    const pageSize = 10;
    final totalPages = (sorted.length + pageSize - 1) ~/ pageSize;

    pw.Widget _pageHeader() => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Center(child: _tx(taadia.title, 43, _pri, true, r)),
      if (hasFilter) ...[
        pw.SizedBox(height: 4),
        pw.Center(
          child: _tx(
            classificationFilter.values.join(' - '),
            20, _muted, false, r,
          ),
        ),
      ],
      pw.SizedBox(height: 4),
    ]);

    for (var p = 0; p < totalPages; p++) {
      final start = p * pageSize;
      final end = (start + pageSize) > sorted.length ? sorted.length : start + pageSize;
      final pageItems = sorted.sublist(start, end);
      final pageRanks = ranks.sublist(start, end);
      doc.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: f, bold: f),
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            _pageHeader(),
            pw.Expanded(child: _buildGroup(pageItems, pageRanks, pageW)),
          ]),
        ),
      );
    }

    final classSuffix = hasFilter ? '_${classificationFilter.values.join('_')}' : '';
    final n = r ? '${taadia.title}$classSuffix.pdf' : '${taadia.title}_Report$classSuffix.pdf';
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
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: f, bold: f),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(eval, sc, ahz, r, l),
            pw.SizedBox(height: 8),
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
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5, color: _bdr),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (_) => eval.questions.map((q) => _qcard(q, r, l)).toList(),
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
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _wht,
        border: pw.Border.all(color: _bdr),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _tx(e.studentName, 28, _pri, true, r),
              pw.Spacer(),
              if (sc != null)
                _bl(
                  sc % 1 == 0 ? '${sc.toInt()}' : sc.toStringAsFixed(1),
                  _pri,
                  r,
                ),
            ],
          ),
          pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 16,
              runSpacing: 6,
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
            pw.SizedBox(height: 8),
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
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _wht,
        border: pw.Border.all(color: _bdr),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _tx('${l.qPrefix}${q.number}', 16, _pri, true, r),
              pw.Spacer(),
              if (q.note.isNotEmpty) _tx(q.note, 12, _muted, true, r),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _tag('${l.ichaarat}: $ic', _pri, r),
              pw.SizedBox(width: 10),
              _tag('${l.taalakin}: $tc', _sec, r),
            ],
          ),
          pw.SizedBox(height: 6),
          ...() {
            final tsets = <pw.Widget>[];
            for (int i = 0; i < q.tSetCount; i++) {
              final t1 = q.topCubes[i * 2];
              final t2 = q.topCubes[i * 2 + 1];
              final b = q.bottomCubes[i];
              if (t1 || t2 || b) {
                tsets.add(_tset(t1, t2, b));
              }
            }
            if (tsets.isEmpty) return [pw.SizedBox()];
            return [pw.Wrap(spacing: 10, runSpacing: 8, children: tsets)];
          }(),
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
          children: [_cube(t1, _pri), pw.SizedBox(width: 6), _cube(t2, _pri)],
        ),
        pw.SizedBox(height: 6),
        _cube(b, _sec),
      ],
    );
  }

  static pw.Widget _cube(bool filled, PdfColor ac) {
    final bg = filled ? PdfColor.fromInt(0xFFF5F0EB) : _wht;
    return pw.Container(
      width: 28,
      height: 28,
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: filled ? ac : _bdr, width: filled ? 3 : 1.5),
      ),
      child: filled
          ? pw.Center(
              child: pw.Text(
                'X',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: ac,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          : pw.SizedBox(),
    );
  }
}
