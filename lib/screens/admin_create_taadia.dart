import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class CreateTaadiaScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _CreateTaadiaScreenState createState() => _CreateTaadiaScreenState();
}

class _CreateTaadiaScreenState extends State<CreateTaadiaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _categoryInputController = TextEditingController();
  final List<String> _categories = [];
  final List<ClassificationConfig> _classifications = [];
  final List<TextEditingController> _classificationOptionControllers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryInputController.dispose();
    for (final c in _classificationOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addClassification() {
    setState(() {
      final idx = _classifications.length;
      final isRtl = AppLocalizations.of(context)!.localeName == 'ar';
      _classifications.add(
        ClassificationConfig(
          name: isRtl ? 'تصنيف ${idx + 1}' : 'Classification ${idx + 1}',
        ),
      );
      _classificationOptionControllers.add(TextEditingController());
    });
  }

  void _removeClassification(int index) {
    setState(() {
      _classificationOptionControllers[index].dispose();
      _classificationOptionControllers.removeAt(index);
      _classifications.removeAt(index);
    });
  }

  void _addClassificationOption(int classIndex) {
    final val = _classificationOptionControllers[classIndex].text.trim();
    if (val.isEmpty) return;
    setState(() {
      final options = List<String>.from(_classifications[classIndex].options);
      options.add(val);
      _classifications[classIndex] = ClassificationConfig(
        name: _classifications[classIndex].name,
        options: options,
      );
      _classificationOptionControllers[classIndex].clear();
    });
  }

  void _removeClassificationOption(int classIndex, int optIndex) {
    setState(() {
      final options = List<String>.from(_classifications[classIndex].options);
      options.removeAt(optIndex);
      _classifications[classIndex] = ClassificationConfig(
        name: _classifications[classIndex].name,
        options: options,
      );
    });
  }

  Future<void> _create() async {
    widget.analytics.logEvent(
      name: 'create_taadia_attempt',
      parameters: {'title': _titleController.text.trim()},
    );
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final taadiaId = await Provider.of<TaadiaService>(context, listen: false)
        .createTaadia(
          _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categories: List.from(_categories),
          classifications: _classifications.where((c) => c.options.isNotEmpty).toList(),
        );

    if (mounted) {
      setState(() => _loading = false);
      if (taadiaId != null) {
        widget.analytics.logEvent(
          name: 'create_taadia_success',
          parameters: {
            'taadia_id': taadiaId,
            'title': _titleController.text.trim(),
          },
        );
        Navigator.pop(context, true);
      } else {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToCreate),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCategory() {
    final value = _categoryInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _categories.add(value);
      _categoryInputController.clear();
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle, ColorScheme cs, bool isRtl) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children, required ColorScheme cs}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: cs.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';

    final inputDecoration = (String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );

    return AppScaffold(
      title: l.createTaadia,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                cs: cs,
                children: [
                  _sectionHeader(Icons.edit_document, l.assessmentTitle, isRtl ? 'عنوان التقييم الذي سيراه الطلاب' : 'The title students will see', cs, isRtl),
                  TextFormField(
                    controller: _titleController,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: inputDecoration(l.assessmentTitle, l.titleHint),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    validator: (v) => v == null || v.trim().isEmpty ? l.enterTitle : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 3,
                    decoration: inputDecoration(l.descriptionOptional, l.descriptionHint),
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),

                _sectionCard(
                  cs: cs,
                  children: [
                    _sectionHeader(Icons.category_rounded, isRtl ? 'التصنيفات' : 'Classifications', isRtl ? 'أضف تصنيفات لتقسيم الطلاب (اختياري)' : 'Add categories to organize students (optional)', cs, isRtl),
                    ...List.generate(_classifications.length, (i) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _classificationOptionControllers[i],
                                    style: TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: isRtl ? 'مثال: نخبة 1 ...' : 'e.g. Group A ...',
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
                                      filled: true,
                                      fillColor: cs.surface.withValues(alpha: 0.8),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.add_circle_outline, size: 20, color: cs.primary),
                                        onPressed: () => _addClassificationOption(i),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ),
                                    onSubmitted: (_) => _addClassificationOption(i),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cs.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                                    tooltip: isRtl ? 'حذف التصنيف' : 'Remove classification',
                                    onPressed: () => _removeClassification(i),
                                    padding: EdgeInsets.all(8),
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                            if (_classifications[i].options.isNotEmpty) ...[
                              SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _classifications[i].options.asMap().entries.map((optEntry) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(optEntry.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _removeClassificationOption(i, optEntry.key),
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: cs.primary.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.close, size: 14, color: cs.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: _addClassification,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18, color: cs.primary),
                            SizedBox(width: 6),
                            Text(isRtl ? 'أضف تصنيفاً' : 'Add classification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(l.create, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l.goBack, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
