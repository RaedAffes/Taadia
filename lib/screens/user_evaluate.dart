
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/services/csv_service.dart';
import 'package:ta3dia/ai/ai_service.dart';
import 'package:ta3dia/widgets/download_choice_dialog.dart';
import 'package:ta3dia/screens/quran_reader_screen.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/widgets/offline_utils.dart';

class _RangeCriterion {
  QuestionRangeType type = QuestionRangeType.hizbRange;
  int? hizbFrom;
  int? hizbTo;
  int? surahFrom;
  int? surahTo;
  final List<int> surahNumbers = [];
  int? ayaFrom;
  int? ayaTo;
  final List<int> quarterNumbers = [];

  QuestionRange toQuestionRange() {
    List<int>? suraNums;
    if (type == QuestionRangeType.surahs && surahFrom != null) {
      suraNums = [for (int i = surahFrom!; i <= (surahTo ?? surahFrom!); i++) i];
    } else if (surahNumbers.isNotEmpty) {
      suraNums = List<int>.from(surahNumbers);
    }
    return QuestionRange(
      type: type,
      hizbFrom: hizbFrom,
      hizbTo: hizbTo ?? hizbFrom,
      surahNumbers: suraNums,
      ayaFrom: ayaFrom,
      ayaTo: ayaTo,
      quarterNumbers: quarterNumbers.isNotEmpty ? List<int>.from(quarterNumbers) : null,
    );
  }

  String summary() {
    switch (type) {
      case QuestionRangeType.hizbRange:
        if (hizbTo == null || hizbTo == hizbFrom) return 'الحزب $hizbFrom';
        if (hizbTo! - hizbFrom! == 1) return 'أحزاب $hizbFrom-$hizbTo';
        return 'من الحزب $hizbFrom إلى $hizbTo';
      case QuestionRangeType.surahs: {
        if (surahFrom == null) return '';
        final fromName = AiService.surahNameAr(surahFrom!) ?? '$surahFrom';
        if (surahTo == null || surahTo == surahFrom) return 'سورة $fromName';
        final toName = AiService.surahNameAr(surahTo!) ?? '$surahTo';
        if (surahTo! - surahFrom! == 1) return 'سور $fromName - $toName';
        return 'من سورة $fromName إلى سورة $toName';
      }
      case QuestionRangeType.surahAyahRange: {
        final name = surahNumbers.isNotEmpty
            ? (AiService.surahNameAr(surahNumbers.first) ?? '')
            : '';
        return 'سورة $name ($ayaFrom-$ayaTo)';
      }
      case QuestionRangeType.quarter: {
        const labels = ['الأول', 'الثاني', 'الثالث', 'الرابع'];
        final selected = quarterNumbers.map((q) => labels[q - 1]).join('، ');
        return 'الربع $selected';
      }
    }
  }

  bool isValid() {
    switch (type) {
      case QuestionRangeType.hizbRange:
        return hizbFrom != null;
      case QuestionRangeType.surahs:
        return surahFrom != null;
      case QuestionRangeType.surahAyahRange:
        return surahNumbers.isNotEmpty;
      case QuestionRangeType.quarter:
        return quarterNumbers.isNotEmpty;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'hizbFrom': hizbFrom,
      'hizbTo': hizbTo,
      'surahFrom': surahFrom,
      'surahTo': surahTo,
      'surahNumbers': List<int>.from(surahNumbers),
      'ayaFrom': ayaFrom,
      'ayaTo': ayaTo,
      'quarterNumbers': List<int>.from(quarterNumbers),
    };
  }

  static _RangeCriterion fromMap(Map<String, dynamic> map) {
    final c = _RangeCriterion();
    c.type = QuestionRangeType.values[map['type'] as int];
    c.hizbFrom = map['hizbFrom'] as int?;
    c.hizbTo = map['hizbTo'] as int?;
    c.surahFrom = map['surahFrom'] as int?;
    c.surahTo = map['surahTo'] as int?;
    c.surahNumbers.addAll((map['surahNumbers'] as List?)?.cast<int>() ?? []);
    c.ayaFrom = map['ayaFrom'] as int?;
    c.ayaTo = map['ayaTo'] as int?;
    c.quarterNumbers
        .addAll((map['quarterNumbers'] as List?)?.cast<int>() ?? []);
    return c;
  }
}

class _QuestionCube extends StatelessWidget {
  final bool filled;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _QuestionCube({
    required this.filled,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : cs.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: filled ? color : cs.outlineVariant,
            width: filled ? 2 : 1,
          ),
        ),
        child: filled
            ? Center(
                child: Icon(Icons.close, size: 18, color: color),
              )
            : null,
      ),
    );
  }
}

class EvaluateScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final String taadiaId;
  final String taadiaTitle;
  final String taadiaDescription;
  final Evaluation? editingEvaluation;
  final List<ClassificationConfig> classifications;
  final bool? active;

  EvaluateScreen({
    required this.taadiaId,
    required this.taadiaTitle,
    this.taadiaDescription = '',
    this.editingEvaluation,
    this.classifications = const [],
    this.active,
  });

  @override
  _EvaluateScreenState createState() => _EvaluateScreenState();
}



class _EvaluateScreenState extends State<EvaluateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _evaluatorNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _noteController = TextEditingController();

  int _numQuestions = 0;
  List<QuestionItem> _questions = [];
  bool _loading = false;
  bool _taadiaActive = true;
  List<String> _category = [];
  List<String> _taadiaCategories = [];
  Map<String, String> _classificationValues = {};
  String? _editingEvaluationId;
  String? _formError;

  bool _isGenerating = false;
  bool _generateEnabled = true;
  int _shortcutIndex = 0;
  final List<int> _questionVerseIndices = [];
  late final PageController _pageController;

  final List<_RangeCriterion> _rangeCriteria = [_RangeCriterion()];
  String _oldAhzabText = '';
  bool _versesLoaded = false;

  bool get _isEditing => _editingEvaluationId != null;

  bool get _isCodeBased =>
      widget.taadiaId.startsWith('code_') ||
      widget.taadiaId.startsWith('pending_code_');

  @override
  void initState() {
    super.initState();
    _editingEvaluationId = widget.editingEvaluation?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(
        screenName: 'evaluate_screen',
        parameters: {
          'taadia_id': widget.taadiaId,
          'taadia_title': widget.taadiaTitle,
          'is_editing': _isEditing.toString(),
        },
      );
    });
    if (widget.active != null) {
      _taadiaActive = widget.active!;
    } else if (!_isCodeBased) {
      _checkTaadiaStatus();
    } else {
      _taadiaActive = true;
    }
    _pageController = PageController();
    AiService.loadVerses().then((_) {
      if (mounted) setState(() => _versesLoaded = true);
    });
    final ts = Provider.of<TaadiaService>(context, listen: false);
    final t = ts.taadias.where((t) => t.id == widget.taadiaId).firstOrNull;
    _taadiaCategories = t?.categories ?? [];

    void loadEval(Evaluation? eval) {
      if (eval == null) return;
      _studentNameController.text = eval.studentName;
      _noteController.text = eval.note;
      _oldAhzabText = eval.specialAhzab;
      _numQuestions = eval.numQuestions;
      _category = List.from(eval.categories);
      _classificationValues = Map.from(eval.classificationValues);
      _editingEvaluationId = eval.id;
      _rangeCriteria
        ..clear()
        ..addAll(
          eval.rangeCriteria.isNotEmpty
              ? eval.rangeCriteria.map((m) => _RangeCriterion.fromMap(m))
              : [_RangeCriterion()],
        );
      if (eval.questions.isNotEmpty) {
        _questions = eval.questions
            .map((q) => QuestionItem(
                  number: q.number,
                  ichaarat: q.ichaarat,
                  taalakin: q.taalakin,
                  note: q.note,
                  questionText: q.questionText,
                  topCubes: List.from(q.topCubes),
                  bottomCubes: List.from(q.bottomCubes),
                ))
            .toList();
        _resetVerseIndices();
      }
    }

    final eval = widget.editingEvaluation;
    if (eval?.evaluatorName.isNotEmpty == true) {
      _evaluatorNameController.text = eval!.evaluatorName;
    }
    final cached = _draftCache[_draftKey];
    if (cached == null) {
      loadEval(eval);
    } else {
      if (eval == null) {
        _restoreDraft(cached);
      } else {
        final evalDraft = _captureDraft();
        final hasChanges = !(evalDraft['numQuestions'] == eval.numQuestions &&
            evalDraft['studentName'] == eval.studentName &&
            evalDraft['note'] == eval.note &&
            !_listDiffers(evalDraft['category'] as List?, eval.categories) &&
            !_mapDiffers(
                evalDraft['classificationValues'] as Map<String, String>?,
                eval.classificationValues));
        if (hasChanges) {
          _restoreDraft(cached);
        } else {
          loadEval(eval);
        }
      }
    }
  }

  static final Map<String, Map<String, dynamic>> _draftCache = {};

  String get _draftKey => '${widget.taadiaId}:${_editingEvaluationId ?? '__new__'}';

  Map<String, dynamic> _captureDraft() {
    return {
      'evaluatorName': _evaluatorNameController.text,
      'studentName': _studentNameController.text,
      'note': _noteController.text,
      'numQuestions': _numQuestions,
      'questions': _questions.map((q) => q.toMap()).toList(),
      'category': _category,
      'classificationValues': Map<String, String>.from(_classificationValues),
      'editingEvaluationId': _editingEvaluationId,
      'formError': _formError,
      'oldAhzabText': _oldAhzabText,
      'rangeCriteria': _rangeCriteria.map((c) => <String, dynamic>{
        'type': c.type.index,
        'hizbFrom': c.hizbFrom,
        'hizbTo': c.hizbTo,
        'surahFrom': c.surahFrom,
        'surahTo': c.surahTo,
        'surahNumbers': List<int>.from(c.surahNumbers),
        'ayaFrom': c.ayaFrom,
        'ayaTo': c.ayaTo,
        'quarterNumbers': List<int>.from(c.quarterNumbers),
      }).toList(),
    };
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    _evaluatorNameController.text = draft['evaluatorName'] as String? ?? '';
    _studentNameController.text = draft['studentName'] as String? ?? '';
    _noteController.text = draft['note'] as String? ?? '';
    _numQuestions = draft['numQuestions'] as int? ?? 0;
    if (draft['questions'] is List) {
      _questions = (draft['questions'] as List).map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return QuestionItem(
          number: map['number'] as int? ?? 0,
          ichaarat: map['ichaarat'] as int? ?? 0,
          taalakin: map['taalakin'] as int? ?? 0,
          note: map['note'] as String? ?? '',
          questionText: map['questionText'] as String? ?? '',
          topCubes: map['topCubes'] != null ? List<bool>.from(map['topCubes'] as List) : [false, false, false],
          bottomCubes: map['bottomCubes'] != null ? List<bool>.from(map['bottomCubes'] as List) : [false],
        );
      }).toList();
      _resetVerseIndices();
    }
    _category = (draft['category'] as List<dynamic>?)?.cast<String>() ?? [];
    _classificationValues =
        Map<String, String>.from(draft['classificationValues'] as Map? ?? {});
    _editingEvaluationId = draft['editingEvaluationId'] as String?;
    _formError = draft['formError'] as String?;
    _oldAhzabText = draft['oldAhzabText'] as String? ?? '';
    if (draft['rangeCriteria'] is List) {
      _rangeCriteria
        ..clear()
        ..addAll((draft['rangeCriteria'] as List).map((m) {
          final map = Map<String, dynamic>.from(m as Map);
          final c = _RangeCriterion();
          c.type = QuestionRangeType.values[map['type'] as int];
          c.hizbFrom = map['hizbFrom'] as int?;
          c.hizbTo = map['hizbTo'] as int?;
          c.surahFrom = map['surahFrom'] as int?;
          c.surahTo = map['surahTo'] as int?;
          c.surahNumbers.addAll(
            (map['surahNumbers'] as List?)?.cast<int>() ?? [],
          );
          c.ayaFrom = map['ayaFrom'] as int?;
          c.ayaTo = map['ayaTo'] as int?;
          final qn = map['quarterNumbers'];
          if (qn is List) {
            c.quarterNumbers.addAll(qn.cast<int>());
          } else if (map['quarterNumber'] is int) {
            c.quarterNumbers.add(map['quarterNumber'] as int);
          }
          return c;
        }));
    }
  }

  static bool _listDiffers(List? a, List? b) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  static bool _mapDiffers(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    for (final key in a.keys) {
      if (a[key] != b[key]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _evaluatorNameController.dispose();
    _studentNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkTaadiaStatus() async {
    final cs = Theme.of(context).colorScheme;
    final active = await Provider.of<TaadiaService>(
      context,
      listen: false,
    ).isTaadiaActive(widget.taadiaId);
    if (mounted) {
      setState(() => _taadiaActive = active);
      if (!active) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.taadiaClosed),
            backgroundColor: cs.tertiary,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final errors = <String>[];
    if (_evaluatorNameController.text.trim().isEmpty) {
      errors.add(l.enterYourName);
    }
    if (_studentNameController.text.trim().isEmpty) {
      errors.add(l.enterStudentName);
    }
    if (_numQuestions == 0) {
      errors.add(l.numberOfQuestions);
    }
    if (_taadiaCategories.isNotEmpty && _category.isEmpty) {
      errors.add(l.selectCategory);
    }
    if (_rangeCriteria.every((c) => !c.isValid())) {
      errors.add(l.enterAhzabRange);
    }
    if (widget.classifications.isNotEmpty) {
      for (final cfg in widget.classifications) {
        if (!_classificationValues.containsKey(cfg.name) ||
            _classificationValues[cfg.name] == null ||
            _classificationValues[cfg.name]!.isEmpty) {
          errors.add('${l.select}: ${cfg.name}');
        }
      }
    }
    for (final q in _questions) {
      q.syncFromCubes();
      if (q.isOverWeight) {
        errors.add('${l.question} ${q.number}: ${l.maxTwoTalakin}');
      }
    }
    if (errors.isNotEmpty) {
      setState(() => _formError = errors.join('\n'));
      return;
    }
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (errors.isNotEmpty) {
      setState(() => _formError = errors.join('\n'));
      return;
    }
    setState(() => _formError = null);

    if (!_taadiaActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotEvaluateClosed),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final evalService = Provider.of<EvaluationService>(context, listen: false);

    for (final q in _questions) {
      q.syncFromCubes();
    }
    final eval = Evaluation(
      id: _editingEvaluationId ?? '',
      taadiaId: widget.taadiaId,
      userId: authService.currentUser!.uid,
      evaluatorName: _evaluatorNameController.text.trim(),
      studentName: _studentNameController.text.trim(),
      categories: _taadiaCategories.isNotEmpty ? _category : [],
      classificationValues: _classificationValues,
      numQuestions: _numQuestions,
      numAhzab: 0,
      specialAhzab: _generateSummary(),
      rangeCriteria: _rangeCriteria.map((c) => c.toMap()).toList(),
      questions: List.from(_questions),
      note: _noteController.text.trim(),
      formula: widget.editingEvaluation?.formula ?? 'mahalia',
      createdAt: DateTime.now(),
    );

    final ok = await evalService.saveEvaluation(eval);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        _draftCache.remove(_draftKey);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? l.updated(_studentNameController.text.trim())
                  : l.evaluated(_studentNameController.text.trim()),
            ),
            backgroundColor: cs.primary,
          ),
        );
        widget.analytics.logEvent(
          name: _isEditing ? 'evaluation_updated' : 'evaluation_submitted',
          parameters: {
            'taadia_id': widget.taadiaId,
            'taadia_title': widget.taadiaTitle,
            'student_name': _studentNameController.text.trim(),
            'evaluator_name': _evaluatorNameController.text.trim(),
            'num_questions': _numQuestions,
            'is_editing': _isEditing.toString(),
          },
        );
        _resetForm();
      }
    }
  }

  Future<void> _generateQuestions({int? singleIndex}) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (guardOffline(context)) return;
    final count = singleIndex != null ? 1 : _numQuestions;
    if (count == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى تحديد عدد الأسئلة أولاً'),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!_hasValidRange()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى تحديد الأحزاب أولاً'),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final (questions, indices) = await AiService.generateDetailed(
        ranges: _rangeCriteria.map((c) => c.toQuestionRange()).toList(),
        count: count,
      );
      if (mounted) {
        final allEmpty = questions.every((q) => q.isEmpty);
        if (allEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.generateFailed),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (singleIndex != null) {
          setState(() {
            _questions[singleIndex].questionText = questions[0];
            _questionVerseIndices[singleIndex] = indices.isNotEmpty ? indices[0] : -1;
          });
        } else {
          setState(() {
            _questions = List.generate(
              count,
              (i) => QuestionItem(
                number: i + 1,
                questionText: i < questions.length ? questions[i] : '',
              ),
            );
            _numQuestions = count;
            _resetVerseIndices();
            for (int i = 0; i < indices.length && i < _questionVerseIndices.length; i++) {
              _questionVerseIndices[i] = indices[i];
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.generateFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  bool _hasValidRange() {
    return _rangeCriteria.any((c) => c.isValid());
  }

  String _generateSummary() {
    final parts = _rangeCriteria
        .where((c) => c.isValid())
        .map((c) => c.summary())
        .toList();
    if (parts.isEmpty) return '';
    return parts.join('، ');
  }

  void _initQuestions(int count) {
    _questions = List.generate(count, (i) => QuestionItem(number: i + 1));
    _resetVerseIndices();
  }

  void _renumberQuestions() {
    for (int i = 0; i < _questions.length; i++) {
      _questions[i] = QuestionItem(
        number: i + 1,
        topCubes: _questions[i].topCubes,
        bottomCubes: _questions[i].bottomCubes,
        ichaarat: _questions[i].ichaarat,
        taalakin: _questions[i].taalakin,
        note: _questions[i].note,
        questionText: _questions[i].questionText,
      );
    }
  }

  void _resetVerseIndices() {
    _questionVerseIndices
      ..clear()
      ..addAll(List.generate(_questions.length, (_) => -1));
  }

  Widget _ayaNavButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    required ColorScheme cs,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }

  void _nextAya(int qIndex) {
    final verses = AiService.allVerses;
    if (verses.isEmpty) return;
    final currentIdx = _questionVerseIndices[qIndex];
    final nextIdx = currentIdx < 0 ? 0 : currentIdx + 1;
    if (nextIdx >= verses.length) return;
    setState(() {
      _questionVerseIndices[qIndex] = nextIdx;
      _questions[qIndex] = QuestionItem(
        number: _questions[qIndex].number,
        topCubes: _questions[qIndex].topCubes,
        bottomCubes: _questions[qIndex].bottomCubes,
        ichaarat: _questions[qIndex].ichaarat,
        taalakin: _questions[qIndex].taalakin,
        note: _questions[qIndex].note,
        questionText: AiService.questionText(verses[nextIdx]),
      );
    });
  }

  void _previousAya(int qIndex) {
    final verses = AiService.allVerses;
    if (verses.isEmpty) return;
    final currentIdx = _questionVerseIndices[qIndex];
    if (currentIdx <= 0) return;
    final prevIdx = currentIdx - 1;
    setState(() {
      _questionVerseIndices[qIndex] = prevIdx;
      _questions[qIndex] = QuestionItem(
        number: _questions[qIndex].number,
        topCubes: _questions[qIndex].topCubes,
        bottomCubes: _questions[qIndex].bottomCubes,
        ichaarat: _questions[qIndex].ichaarat,
        taalakin: _questions[qIndex].taalakin,
        note: _questions[qIndex].note,
        questionText: AiService.questionText(verses[prevIdx]),
      );
    });
  }

  void _showWeightError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.maxTwoTalakin),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUncheckMessage(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.uncheckQuestionFirst),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetForm() {
    _studentNameController.clear();
    _noteController.clear();
    setState(() {
      _numQuestions = 0;
      _questions = [];
      _category = [];
      _editingEvaluationId = null;
      _formError = null;
      _oldAhzabText = '';
      _rangeCriteria.clear();
      _rangeCriteria.add(_RangeCriterion());
    });
    _resetVerseIndices();
  }

  void _startEdit(Evaluation e) {
    Navigator.pop(context);
    _draftCache.remove(_draftKey);
    _evaluatorNameController.text = e.evaluatorName;
    _studentNameController.text = e.studentName;
    _noteController.text = e.note;
    setState(() {
      _oldAhzabText = e.specialAhzab;
      _numQuestions = e.numQuestions;
      _category = List.from(e.categories);
      _classificationValues = Map.from(e.classificationValues);
      _editingEvaluationId = e.id;
      _formError = null;
      _rangeCriteria.clear();
      if (e.rangeCriteria.isNotEmpty) {
        _rangeCriteria.addAll(
          e.rangeCriteria.map((m) => _RangeCriterion.fromMap(m)),
        );
      } else {
        _rangeCriteria.add(_RangeCriterion());
      }
      if (e.questions.isNotEmpty) {
        _questions = e.questions
            .map((q) => QuestionItem(
                  number: q.number,
                  ichaarat: q.ichaarat,
                  taalakin: q.taalakin,
                  note: q.note,
                  questionText: q.questionText,
                  topCubes: List.from(q.topCubes),
                  bottomCubes: List.from(q.bottomCubes),
                ))
            .toList();
        _resetVerseIndices();
      }
    });
  }

  void _showEvaluationsList() {
    final cs = Theme.of(context).colorScheme;
    final evalService = Provider.of<EvaluationService>(context, listen: false);
    evalService.loadMyEvaluations(widget.taadiaId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.myEvaluations,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: Consumer<EvaluationService>(
                      builder: (context, service, _) {
                        final l = AppLocalizations.of(context)!;
                        if (service.isLoading)
                          return Center(child: CircularProgressIndicator());
                        if (service.evaluations.isEmpty)
                          return Center(child: Text(l.noEvaluationsYet));
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: service.evaluations.length,
                          itemBuilder: (context, index) {
                            final e = service.evaluations[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          cs.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        color: cs.primary,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.studentName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                if (e.specialAhzab.isNotEmpty)
                                                  _evalChip(
                                                    e.specialAhzab,
                                                    cs.outlineVariant,
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.download,
                                        color: cs.secondary,
                                      ),
                                      onPressed: () async {
                                        try {
                                          final l = AppLocalizations.of(
                                            context,
                                          )!;
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
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: cs.primary,
                                      ),
                                      onPressed: () => _startEdit(e),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: cs.error,
                                      ),
                                      onPressed: () async {
                                        await service.deleteEvaluation(e.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuranOverlay(int verseIndex) {
    if (verseIndex < 0 || verseIndex >= AiService.allVerses.length) return;
    final verse = AiService.allVerses[verseIndex];
    final suraNo = verse['sura_no'] as int;
    final ayaNo = verse['aya_no'] as int;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final mq = MediaQuery.of(context);
        final maxH = mq.size.height - mq.padding.top - mq.viewInsets.bottom - 24;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: maxH.clamp(200.0, mq.size.height),
            child: QuranReaderScreen(
              initialSurah: suraNo,
              initialAyah: ayaNo,
              pageKey: 'gen-$suraNo-$ayaNo',
            ),
          ),
        );
      },
    );
  }

  Widget _questionWidget(int index, AppLocalizations l, ColorScheme cs) {
    final q = _questions[index];
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: q.isComplete ? cs.primary.withValues(alpha: 0.04) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: q.isComplete
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.8),
                        cs.primary.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${q.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l.question} ${q.number}',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Checkbox(
                  value: q.isComplete,
                  onChanged: (v) => setState(() => q.isComplete = v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          if (q.questionText.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 120),
                  padding: EdgeInsets.all(12),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.08),
                        cs.secondary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ayaNavButton(
                            icon: Icons.skip_previous,
                            tooltip: 'Next Aya',
                            enabled: true,
                            onPressed: () => _nextAya(index),
                            cs: cs,
                          ),
                          SizedBox(width: 2),
                          _ayaNavButton(
                            icon: Icons.refresh,
                            tooltip: 'Regenerate',
                            enabled: _versesLoaded && !_isGenerating && _generateEnabled && _hasValidRange(),
                            onPressed: q.isComplete
                                ? () => _showUncheckMessage(context)
                                : () => _generateQuestions(singleIndex: index),
                            cs: cs,
                          ),
                          SizedBox(width: 2),
                          _ayaNavButton(
                            icon: Icons.skip_next,
                            tooltip: 'Previous Aya',
                            enabled: true,
                            onPressed: () => _previousAya(index),
                            cs: cs,
                          ),
                          SizedBox(width: 2),
                          _ayaNavButton(
                            icon: Icons.menu_book,
                            tooltip: 'Open in Quran',
                            enabled: true,
                            onPressed: () => _showQuranOverlay(_questionVerseIndices[index]),
                            cs: cs,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            q.questionText,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(q.tSetCount, (tSetIndex) {
                      final top1 = q.topCubes[tSetIndex * 2];
                      final top2 = q.topCubes[tSetIndex * 2 + 1];
                      final bottom = q.bottomCubes[tSetIndex];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            _QuestionCube(
                              filled: top1,
                              color: cs.primary,
                              onTap: q.isComplete
                                  ? () => _showUncheckMessage(context)
                                  : () {
                                      setState(() {
                                        final old = q.topCubes.toList();
                                        q.topCubes[tSetIndex * 2] = !q.topCubes[tSetIndex * 2];
                                        q.syncFromCubes();
                                        if (q.isOverWeight) {
                                          q.topCubes = old;
                                          q.syncFromCubes();
                                          _showWeightError();
                                        }
                                      });
                                    },
                            ),
                            SizedBox(width: 4),
                            _QuestionCube(
                              filled: top2,
                              color: cs.primary,
                              onTap: q.isComplete
                                  ? () => _showUncheckMessage(context)
                                  : () {
                                      setState(() {
                                        final old = q.topCubes.toList();
                                        q.topCubes[tSetIndex * 2 + 1] =
                                            !q.topCubes[tSetIndex * 2 + 1];
                                        q.syncFromCubes();
                                        if (q.isOverWeight) {
                                          q.topCubes = old;
                                          q.syncFromCubes();
                                          _showWeightError();
                                        }
                                      });
                                    },
                            ),
                            ],
                          ),
                          SizedBox(height: 4),
                        _QuestionCube(
                          filled: bottom,
                          color: cs.secondary,
                          onTap: q.isComplete
                              ? () => _showUncheckMessage(context)
                              : () {
                                  setState(() {
                                    final newVal = !q.bottomCubes[tSetIndex];
                                    q.bottomCubes[tSetIndex] = newVal;
                                    if (newVal) {
                                      q.topCubes[tSetIndex * 2] = true;
                                      q.topCubes[tSetIndex * 2 + 1] = true;
                                    }
                                    q.syncFromCubes();
                                    if (q.isOverWeight) {
                                      final excess = q.weightedScore - 2.0;
                                      final needRemove = (excess / 0.25).ceil();
                                      final available = q.countRemovableIchaarat(skipTSet: tSetIndex);
                                      if (available >= needRemove) {
                                        q.deselectIchaarat(needRemove, skipTSet: tSetIndex);
                                        q.syncFromCubes();
                                      } else {
                                        q.bottomCubes[tSetIndex] = !newVal;
                                        if (newVal) {
                                          q.topCubes[tSetIndex * 2] = false;
                                          q.topCubes[tSetIndex * 2 + 1] = false;
                                        }
                                        q.syncFromCubes();
                                      }
                                      _showWeightError();
                                    }
                                  });
                                },
                        ),
                        ],
                      );
                    }),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.add, size: 18, color: cs.primary),
                                tooltip: 'Add T-set',
                                onPressed: q.isComplete
                                    ? () => _showUncheckMessage(context)
                                    : () {
                                        setState(() {
                                          q.addTSet();
                                          q.syncFromCubes();
                                          if (q.isOverWeight) {
                                            q.removeTSet();
                                            q.syncFromCubes();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppLocalizations.of(context)!.maxTwoTalakin),
                                                backgroundColor: cs.error,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        });
                                      },
                              ),
                              IconButton(
                                icon: Icon(Icons.remove, size: 18, color: cs.error),
                                tooltip: 'Remove T-set',
                                onPressed: q.isComplete && q.tSetCount <= 1
                                    ? null
                                    : q.isComplete
                                        ? () => _showUncheckMessage(context)
                                        : q.tSetCount <= 1
                                            ? null
                                            : () {
                                                setState(() {
                                                  q.removeTSet();
                                                  q.syncFromCubes();
                                                });
                                              },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.06),
                    cs.secondary.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _scoreBox(
                      Icons.notifications,
                      '${q.ichaarat}',
                      l.totalIchaarat,
                      cs.primary,
                    ),
                  ),
                  Container(
                  width: 1,
                  height: 36,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _scoreBox(
                    Icons.record_voice_over,
                    '${q.taalakin}',
                    l.totalTaalakin,
                    cs.secondary,
                  ),
                ),
              ],
            ),
          ),
          ),
          SizedBox(height: 28),
          if (q.note.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
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
          TextField(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l.enterNoteHint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: TextStyle(fontSize: 13),
            readOnly: q.isComplete,
            onTap: q.isComplete ? () => _showUncheckMessage(context) : null,
            onChanged: q.isComplete ? null : (v) => q.note = v,
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionCard(int index, ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final c = _rangeCriteria[index];
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<QuestionRangeType>(
                      value: c.type,
                      isExpanded: true,
                      isDense: true,
                      items: [
                        DropdownMenuItem(value: QuestionRangeType.quarter, child: Text(l.rangeQuarter, style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: QuestionRangeType.hizbRange, child: Text(l.rangeHizbRange, style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: QuestionRangeType.surahs, child: Text(l.rangeSurahs, style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: QuestionRangeType.surahAyahRange, child: Text(l.rangeSurahAyahRange, style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          c.type = v;
                          if (v != QuestionRangeType.surahs && v != QuestionRangeType.surahAyahRange) {
                            c.surahNumbers.clear();
                          }
                          if (v != QuestionRangeType.surahAyahRange) {
                            c.ayaFrom = null;
                            c.ayaTo = null;
                          }
                          if (v != QuestionRangeType.hizbRange) {
                            c.hizbFrom = null;
                            c.hizbTo = null;
                          }
                          if (v != QuestionRangeType.quarter) {
                            c.quarterNumbers.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              if (_rangeCriteria.length > 1)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: cs.error),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _rangeCriteria.removeAt(index));
                  },
                ),
            ],
          ),
          SizedBox(height: 10),
          _buildCriterionInputs(index, cs),
        ],
      ),
    );
  }

  Widget _buildCriterionInputs(int index, ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final c = _rangeCriteria[index];
    switch (c.type) {
      case QuestionRangeType.hizbRange:
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(child: _hizbDropdown(cs, c.hizbTo, (v) {
                setState(() => c.hizbTo = v);
              }, label: l.to)),
              SizedBox(width: 8),
              Expanded(child: _hizbDropdown(cs, c.hizbFrom, (v) {
                setState(() {
                  c.hizbFrom = v;
                  if (c.hizbTo == null || c.hizbTo == c.hizbFrom) {
                    c.hizbTo = v;
                  }
                });
              }, label: l.from)),
            ],
          ),
        );

      case QuestionRangeType.surahs:
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(child: _surahDropdown(cs, c.surahTo ?? c.surahFrom, (v) {
                setState(() => c.surahTo = v);
              }, hintText: l.to)),
              SizedBox(width: 8),
              Expanded(child: _surahDropdown(cs, c.surahFrom, (v) {
                setState(() => c.surahFrom = v);
              }, hintText: l.from)),
            ],
          ),
        );

      case QuestionRangeType.surahAyahRange:
        final suraNo = c.surahNumbers.isNotEmpty ? c.surahNumbers.first : null;
        return Column(
          children: [
            _surahDropdown(cs, suraNo, (v) {
              setState(() {
                c.surahNumbers.clear();
                if (v != null) c.surahNumbers.add(v);
                c.ayaFrom = null;
                c.ayaTo = null;
              });
            }, hintText: c.surahNumbers.isNotEmpty ? l.addSurah : l.selectSurah),
            if (suraNo != null) ...[
              SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Expanded(
                      child: _ayahField(cs, c.ayaTo, (v) {
                        setState(() => c.ayaTo = v);
                      }, label: l.toAyah, max: AiService.surahAyaCount(suraNo) ?? 0),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _ayahField(cs, c.ayaFrom, (v) {
                        setState(() => c.ayaFrom = v);
                      }, label: l.fromAyah, max: AiService.surahAyaCount(suraNo) ?? 0),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case QuestionRangeType.quarter:
        return _quarterSelector(cs, c);
    }
  }

  Widget _hizbDropdown(ColorScheme cs, int? value, ValueChanged<int?> onChanged, {required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          items: List.generate(60, (i) => i + 1).map((n) {
            return DropdownMenuItem(value: n, child: Text('$n', style: TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _surahDropdown(ColorScheme cs, int? value, ValueChanged<int?> onChanged, {required String hintText}) {
    final surahs = AiService.surahList;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(hintText, style: TextStyle(fontSize: 13)),
          items: surahs.map((s) {
            final no = s['number'] as int;
            final name = s['nameAr'] as String? ?? '';
            return DropdownMenuItem(value: no, child: Text('$no. $name', style: TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _ayahField(ColorScheme cs, int? value, ValueChanged<int?> onChanged, {required String label, required int max}) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      style: TextStyle(fontSize: 13),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null && parsed >= 1 && parsed <= max) {
          onChanged(parsed);
        } else {
          onChanged(null);
        }
      },
    );
  }

  Widget _quarterSelector(ColorScheme cs, _RangeCriterion c) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(4, (i) {
        final q = i + 1;
        final selected = c.quarterNumbers.contains(q);
        return ChoiceChip(
          label: Text(l.quarterLabel(q), style: TextStyle(fontSize: 12)),
          selected: selected,
          selectedColor: cs.primary.withValues(alpha: 0.15),
          visualDensity: VisualDensity.compact,
          onSelected: _isGenerating
              ? null
              : (val) {
                  setState(() {
                    if (val) {
                      c.quarterNumbers.add(q);
                    } else {
                      c.quarterNumbers.remove(q);
                    }
                  });
                },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _draftCache[_draftKey] = _captureDraft();
      },
      child: AppScaffold(
      title: widget.taadiaTitle,
      actions: [
        IconButton(
          icon: Icon(Icons.menu_book),
          tooltip: 'القرآن',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuranReaderScreen(pageKey: 'eval-appbar')),
          ),
        ),
        IconButton(
          icon: Icon(Icons.list),
          tooltip: l.myEvaluations,
          onPressed: _showEvaluationsList,
        ),
      ],
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: _taadiaActive
          ? SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.studentEvaluation,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    Builder(builder: (ctx) {
                      final ts = Provider.of<TaadiaService>(ctx, listen: true);
                      final t = ts.taadias.where((t) => t.id == widget.taadiaId).firstOrNull;
                      if (t == null || t.accessCode.isEmpty) return SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
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
                                t.accessCode,
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
                                  Clipboard.setData(ClipboardData(text: t.accessCode));
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
                      );
                    }),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _evaluatorNameController,
                      decoration: InputDecoration(
                        labelText: l.evaluatorName,
                        hintText: l.yourNameHint,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: InputDecoration(
                        labelText: l.studentName,
                        hintText: l.studentNameHint,
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (widget.classifications.isNotEmpty) ...[
                      SizedBox(height: 16),
                      ...widget.classifications.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cfg = entry.value;
                        final savedValue = _classificationValues[cfg.name];
                        final validValue = cfg.options.contains(savedValue) ? savedValue : null;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('class_${cfg.name}'),
                            initialValue: validValue,
                            autovalidateMode: AutovalidateMode.disabled,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return isRtl ? 'اختر كلمة' : 'Please select an option';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: cfg.name.isNotEmpty
                                  ? cfg.name
                                  : '${l.select} ${i + 1}',
                              hintText: l.select,
                              prefixIcon: Icon(Icons.label_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: cfg.options.map((opt) {
                              return DropdownMenuItem(
                                value: opt,
                                child: Text(opt, style: TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                if (val != null) {
                                  _classificationValues[cfg.name] = val;
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                    if (_taadiaCategories.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.category_outlined, size: 20, color: cs.primary),
                                SizedBox(width: 8),
                                Text(
                                  l.selectCategory,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _taadiaCategories.map((cat) {
                                final selected = _category.contains(cat);
                                return FilterChip(
                                  label: Text(cat),
                                  selected: selected,
                                  selectedColor: cs.primary.withValues(alpha: 0.15),
                                  checkmarkColor: cs.primary,
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        _category.add(cat);
                                      } else {
                                        _category.remove(cat);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _numQuestions > 0 ? _numQuestions : null,
                          hint: Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 20,
                                color: cs.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                l.numberOfQuestions,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                          isExpanded: true,
                          items: List.generate(60, (i) => i + 1).map((n) {
                            return DropdownMenuItem(
                              value: n,
                              child: Text('$n'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final count = val ?? 0;
                            setState(() {
                              _numQuestions = count;
                              _initQuestions(count);
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Old range info banner
                    if (_oldAhzabText.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.tertiary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.tertiary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: cs.tertiary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l.previousRange(_oldAhzabText),
                                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                                onPressed: () => setState(() => _oldAhzabText = ''),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Range criteria cards
                    ...List.generate(_rangeCriteria.length, (i) =>
                        _buildCriterionCard(i, cs)),

                    // Add criterion button
                    Center(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.add, size: 18),
                        label: Text(l.addRange),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          setState(() => _rangeCriteria.add(_RangeCriterion()));
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Generate button
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: _isGenerating
                                    ? SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                                      )
                                    : Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isGenerating ? l.generating : l.generateQuestions),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: (!_versesLoaded || _isGenerating || !_generateEnabled) ? null : () => _generateQuestions(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Switch(
                            value: _generateEnabled,
                            onChanged: (v) => setState(() {
                              _generateEnabled = v;
                              if (!v) {
                                for (final q in _questions) {
                                  q.questionText = '';
                                }
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (!_versesLoaded)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'جاري تحميل الآيات...',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 16),
                    if (_questions.isNotEmpty) ...[
                      Text(
                        l.questions,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 16),
                      _QuestionPager(
                        controller: _pageController,
                        itemCount: _questions.length,
                        itemBuilder: (i) => _questionWidget(i, l, cs),
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(Icons.add, size: 18),
                              label: Text(l.add),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _questions.length < 60
                                  ? () {
                                      final idx = _questions.length;
                                      setState(() {
                                        _questions.add(QuestionItem(
                                            number: idx + 1));
                                        _numQuestions = _questions.length;
                                      });
                                      _resetVerseIndices();
                                      _pageController.animateToPage(
                                        idx,
                                        duration: Duration(milliseconds: 350),
                                        curve: Curves.easeInOut,
                                      );
                                      if (!_isGenerating && _generateEnabled && _hasValidRange()) {
                                        _generateQuestions(singleIndex: idx);
                                      }
                                    }
                                  : null,
                            ),
                            SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: Icon(Icons.remove, size: 18),
                              label: Text(l.remove),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _questions.length > 1
                                  ? () {
                                      final curIdx = _pageController.page?.round() ?? 0;
                                      setState(() {
                                        _questions.removeLast();
                                        _numQuestions = _questions.length;
                                      });
                                      _resetVerseIndices();
                                      final newIdx = curIdx.clamp(0, _questions.length - 1);
                                      _pageController.animateToPage(
                                        newIdx,
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    Text(
                      l.note,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: l.enterNoteHint),
                    ),
                    if (_formError != null)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cs.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _formError!
                                .split('\n')
                                .map(
                                  (e) => Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 16,
                                          color: cs.error,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              color: cs.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: cs.onPrimary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                            : Text(
                                _isEditing
                                    ? l.updateEvaluation
                                    : l.saveEvaluation,
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _resetForm,
                        icon: Icon(_isEditing ? Icons.close : Icons.refresh),
                        label: Text(
                          _isEditing ? l.cancelEdit : l.startNewStudent,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: cs.outlineVariant),
                  SizedBox(height: 16),
                  Text(
                    l.taadiaClosed,
                    style: TextStyle(fontSize: 18, color: cs.primary),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                onPressed: () => Navigator.pop(context),
                    child: Text(l.goBack),
                  ),
                ],
              ),
            ),
      ),
      ),
    );
  }

  void _showShortcutPanel() {
    _shortcutIndex = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              maxChildSize: 0.95,
              minChildSize: 0.35,
              builder: (ctx2, sc) {
                final cs = Theme.of(context).colorScheme;
                return _shortcutBody(cs, setSheetState, sc, ctx2);
              },
            );
          },
        );
      },
    );
  }

  Widget _shortcutBody(ColorScheme cs, void Function(void Function()) setSheetState,
      ScrollController sc, BuildContext sheetCtx) {
    final q = _questions[_shortcutIndex];
    return SingleChildScrollView(
      controller: sc,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_upward, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: _shortcutIndex > 0
                    ? () => setSheetState(() => _shortcutIndex--)
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: _shortcutIndex < _questions.length - 1
                    ? () => setSheetState(() => _shortcutIndex++)
                    : null,
              ),
              SizedBox(width: 8),
              Text('${_shortcutIndex + 1} / ${_questions.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.onSurface)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.fullscreen, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Expand',
                onPressed: () => Navigator.pop(sheetCtx),
              ),
            ],
          ),
          if (q.questionText.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.08),
                    cs.secondary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Text(q.questionText,
                  style: TextStyle(fontSize: 13, height: 1.5),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right),
            ),
          ],
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(q.tSetCount, (tSetIndex) {
                    final top1 = q.topCubes[tSetIndex * 2];
                    final top2 = q.topCubes[tSetIndex * 2 + 1];
                    final bottom = q.bottomCubes[tSetIndex];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _shortcutCube(
                              filled: top1,
                              color: cs.primary,
                              onTap: () {
                                setSheetState(() {
                                  final old = q.topCubes.toList();
                                  q.topCubes[tSetIndex * 2] =
                                      !q.topCubes[tSetIndex * 2];
                                  q.syncFromCubes();
                                  if (q.isOverWeight) {
                                    q.topCubes = old;
                                    q.syncFromCubes();
                                  }
                                });
                              },
                            ),
                            SizedBox(width: 3),
                            _shortcutCube(
                              filled: top2,
                              color: cs.primary,
                              onTap: () {
                                setSheetState(() {
                                  final old = q.topCubes.toList();
                                  q.topCubes[tSetIndex * 2 + 1] =
                                      !q.topCubes[tSetIndex * 2 + 1];
                                  q.syncFromCubes();
                                  if (q.isOverWeight) {
                                    q.topCubes = old;
                                    q.syncFromCubes();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        _shortcutCube(
                          filled: bottom,
                          color: cs.secondary,
                          onTap: () {
                            setSheetState(() {
                              final newVal = !q.bottomCubes[tSetIndex];
                              q.bottomCubes[tSetIndex] = newVal;
                              if (newVal) {
                                q.topCubes[tSetIndex * 2] = true;
                                q.topCubes[tSetIndex * 2 + 1] = true;
                              }
                              q.syncFromCubes();
                              if (q.isOverWeight) {
                                final excess = q.weightedScore - 2.0;
                                final needRemove = (excess / 0.25).ceil();
                                final available = q.countRemovableIchaarat(skipTSet: tSetIndex);
                                if (available >= needRemove) {
                                  q.deselectIchaarat(needRemove, skipTSet: tSetIndex);
                                  q.syncFromCubes();
                                } else {
                                  q.bottomCubes[tSetIndex] = !newVal;
                                  if (newVal) {
                                    q.topCubes[tSetIndex * 2] = false;
                                    q.topCubes[tSetIndex * 2 + 1] = false;
                                  }
                                  q.syncFromCubes();
                                }
                                _showWeightError();
                              }
                            });
                          },
                        ),
                      ],
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 16, color: cs.primary),
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      setSheetState(() {
                        q.addTSet();
                        q.syncFromCubes();
                        if (q.isOverWeight) {
                          q.removeTSet();
                          q.syncFromCubes();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.remove, size: 16, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: q.tSetCount > 1
                        ? () => setSheetState(() {
                              q.removeTSet();
                              q.syncFromCubes();
                            })
                        : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.notifications, size: 14, color: cs.primary),
              SizedBox(width: 4),
              Text('${q.ichaarat}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
              SizedBox(width: 4),
              Text('Ichaarat',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 16),
              Icon(Icons.record_voice_over, size: 14, color: cs.secondary),
              SizedBox(width: 4),
              Text('${q.taalakin}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary)),
              SizedBox(width: 4),
              Text('Taalakin',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 10),
          if (q.note.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(q.note,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ),
            SizedBox(height: 8),
          ],
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter a note...',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: TextStyle(fontSize: 13),
            onChanged: (v) {
              q.note = v;
              setSheetState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _shortcutCube({
    required bool filled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: filled ? color : color.withValues(alpha: 0.4),
            width: filled ? 2 : 1,
          ),
        ),
        child: filled
            ? Center(
                child: Icon(Icons.close, size: 14, color: color))
            : null,
      ),
    );
  }

  Widget _evalChip(String text, Color color) {
    return Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QuestionPager extends StatefulWidget {
  final PageController controller;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _QuestionPager({
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<_QuestionPager> createState() => _QuestionPagerState();
}

class _QuestionPagerState extends State<_QuestionPager> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: PageView.builder(
              controller: widget.controller,
              itemCount: widget.itemCount,
              itemBuilder: (_, i) => RepaintBoundary(
                child: widget.itemBuilder(i),
              ),
            ),
          ),
        ),
        if (widget.itemCount > 1) ...[
          SizedBox(height: 12),
          _DotsNav(
            controller: widget.controller,
            count: widget.itemCount,
            cs: cs,
          ),
        ],
      ],
    );
  }
}

class _DotsNav extends StatefulWidget {
  final PageController controller;
  final int count;
  final ColorScheme cs;

  const _DotsNav({
    required this.controller,
    required this.count,
    required this.cs,
  });

  @override
  State<_DotsNav> createState() => _DotsNavState();
}

class _DotsNavState extends State<_DotsNav> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.controller.initialPage;
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _DotsNav old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _index = widget.controller.initialPage;
    }
    if (_index >= widget.count) {
      _index = widget.count - 1;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final page = widget.controller.page;
    if (page == null) return;
    final nearest = page.round();
    if (nearest != _index) {
      setState(() => _index = nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final spacing = 14.0;
    final canPrev = _index > 0;
    final canNext = _index < widget.count - 1;
    final totalW = widget.count * spacing;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, size: 18),
              tooltip: 'Next',
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: canNext
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: canNext
                  ? () => widget.controller.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
            SizedBox(
              width: 200,
              height: 8,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final viewW = constraints.maxWidth;
                  final maxOff = (totalW - viewW + 14).clamp(0.0, double.infinity);
                  final targetOff = (_index * spacing - viewW / 2 + 7).clamp(0.0, maxOff);
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: -targetOff,
                        child: SizedBox(
                          width: totalW + 10,
                          height: 8,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              ...List.generate(widget.count, (i) {
                                return Positioned(
                                  left: i * spacing + 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: cs.outlineVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                              Positioned(
                                left: _index * spacing,
                                child: Container(
                                  width: 24,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, size: 18),
              tooltip: 'Previous',
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: canPrev
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: canPrev
                  ? () => widget.controller.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
