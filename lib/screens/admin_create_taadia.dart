import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/models/user_model.dart';
import 'package:ta3dia/models/group_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/string_utils.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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

  Set<String> _selectedGroupIds = {};
  Set<String> _selectedUserIds = {};
  bool _isManualCode = false;
  String _accessCode = '';
  String _manualCode = '';
  final _accessCodeController = TextEditingController();
  final _accessCodeFocusNode = FocusNode();
  String? _codeError;
  final _categoryInputController = TextEditingController();
  final List<String> _categories = [];
  final List<ClassificationConfig> _classifications = [];
  final List<TextEditingController> _classificationOptionControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      await Provider.of<GroupService>(context, listen: false).loadGroups();
      setState(() {
        _accessCode = taadiaService.generateAccessCode();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _accessCodeController.dispose();
    _accessCodeFocusNode.dispose();
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

  void _regenerateCode() {
    setState(() {
      _accessCode = Provider.of<TaadiaService>(
        context,
        listen: false,
      ).generateAccessCode();
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

    if (_isManualCode) {
      final code = _accessCodeController.text.trim();
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      final existing = taadiaService.validateAccessCode(code);
      if (existing != null) {
        setState(
          () => _codeError = AppLocalizations.of(context)!.codeAlreadyUsed,
        );
        return;
      }
    }

    setState(() => _loading = true);

    final selectedGroups = <String, bool>{};
    for (final gid in _selectedGroupIds) {
      selectedGroups[gid] = true;
    }
    final selectedUsers = <String, bool>{};
    for (final uid in _selectedUserIds) {
      selectedUsers[uid] = true;
    }

    final code = _isManualCode
        ? _accessCodeController.text.trim()
        : _accessCode;
    final taadiaId = await Provider.of<TaadiaService>(context, listen: false)
        .createTaadia(
          _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          accessGroups: selectedGroups,
          accessUsers: selectedUsers,
          accessCode: code,
          categories: List.from(_categories),
          classifications: List.from(_classifications),
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

  void _showUserPicker() {
    showDialog(
      context: context,
      builder: (ctx) => _UserPickerDialog(
        selectedGroupIds: _selectedGroupIds,
        selectedUserIds: _selectedUserIds,
        onDone: (groupIds, userIds) {
          setState(() {
            _selectedGroupIds = groupIds;
            _selectedUserIds = userIds;
          });
        },
      ),
    );
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
    final groupService = context.watch<GroupService>();
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

              _sectionCard(
                cs: cs,
                children: [
                  _sectionHeader(Icons.people_outline, l.accessControl, l.accessControlDesc, cs, isRtl),
                  InkWell(
                    onTap: _showUserPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_add_outlined, size: 18, color: cs.primary),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.selectUsers, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                if (_selectedUserIds.isNotEmpty)
                                  Text('${_selectedUserIds.length} ${l.usersSelected.toLowerCase()}', style: TextStyle(fontSize: 12, color: cs.primary)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              _sectionCard(
                cs: cs,
                children: [
                  _sectionHeader(Icons.vpn_key_rounded, l.accessCode, l.accessCodeDesc, cs, isRtl),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.autoGenerate,
                          style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: !_isManualCode,
                            activeColor: cs.primary,
                              onChanged: (v) {
                                setState(() {
                                  _isManualCode = !v;
                                  _codeError = null;
                                  if (_isManualCode) {
                                    _accessCodeController.text = _manualCode.isNotEmpty ? _manualCode : _accessCode;
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _accessCodeFocusNode.requestFocus();
                                    });
                                  } else {
                                    _manualCode = _accessCodeController.text;
                                  }
                                });
                              },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  if (_isManualCode)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key, size: 20, color: cs.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _accessCodeController,
                              focusNode: _accessCodeFocusNode,
                              decoration: InputDecoration(
                                hintText: l.accessCodeHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                counterText: '',
                                hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                              ),
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: cs.primary),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              onChanged: (v) {
                                _manualCode = v;
                                setState(() => _codeError = null);
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return l.accessCodeHint;
                                if (v.trim().length != 4) return l.accessCodeHint;
                                if (int.tryParse(v.trim()) == null) return l.invalidCode;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key, size: 20, color: cs.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: SelectableText(
                              _accessCode,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: cs.primary),
                            ),
                          ),
                          _codeAction(Icons.copy_rounded, l.copy, cs, () {
                            Clipboard.setData(ClipboardData(text: _accessCode));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                          }),
                          SizedBox(width: 4),
                          _codeAction(Icons.refresh_rounded, l.regenerateCode, cs, _regenerateCode),
                        ],
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

  Widget _codeAction(IconData icon, String tooltip, ColorScheme cs, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
      ),
    );
  }
}

class _UserPickerDialog extends StatefulWidget {
  final Set<String> selectedGroupIds;
  final Set<String> selectedUserIds;
  final void Function(Set<String> groupIds, Set<String> userIds) onDone;

  const _UserPickerDialog({
    required this.selectedGroupIds,
    required this.selectedUserIds,
    required this.onDone,
  });

  @override
  __UserPickerDialogState createState() => __UserPickerDialogState();
}

class __UserPickerDialogState extends State<_UserPickerDialog> {
  late Set<String> _selectedGroups;
  late Set<String> _selectedUsers;
  final _searchController = TextEditingController();
  String? _currentUid;

  List<MapEntry<String, AppUser>> _allUsers = [];
  List<MapEntry<String, AppUser>> _filteredUsers = [];
  List<GroupModel> _adminGroups = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _selectedGroups = Set.from(widget.selectedGroupIds);
    _selectedUsers = Set.from(widget.selectedUserIds);
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    _currentUid = auth.currentUser?.uid;
    final users = await auth.getAllUsers();
    _allUsers = users
        .where((u) => !u.isAdmin)
        .map((u) => MapEntry(u.uid, u))
        .toList();
    _allUsers.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
    _filteredUsers = List.from(_allUsers);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('groups').get();
      _adminGroups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (_) {
      _adminGroups = [];
    }
    _loaded = true;
    if (mounted) setState(() {});
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final q = normalizeArabic(query.toLowerCase());
        _filteredUsers = _allUsers
            .where(
              (e) =>
                  normalizeArabic(
                    e.value.displayName.toLowerCase(),
                  ).contains(q) ||
                  e.value.email.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.people, size: 20, color: cs.onPrimaryContainer),
                ),
                SizedBox(width: 10),
                Text(
                  l.selectUsers,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchByName,
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: _filter,
            ),
          ),
          Flexible(
            child: !_loaded
                ? Center(child: CircularProgressIndicator())
                : _buildContent(l),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onDone(_selectedGroups, _selectedUsers);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l.done),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l) {
    final List<Widget> children = [];
    final isRtl = l.localeName == 'ar';

    final adminGroups = _adminGroups;

    if (adminGroups.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            isRtl ? 'المجموعات' : 'Groups',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
      final allGroupsSelected = adminGroups.every(
        (g) => _selectedGroups.contains(g.id),
      );

      children.add(
        _buildSelectAllTile(
          isSelected: allGroupsSelected,
          label: allGroupsSelected
              ? (isRtl ? 'إلغاء تحديد الكل' : 'Deselect all')
              : (isRtl ? 'تحديد الكل' : 'Select all'),
          onSelect: (checked) {
            setState(() {
              if (checked == true) {
                for (final group in adminGroups) {
                  _selectedGroups.add(group.id);
                  for (final uid in group.members.keys) {
                    _selectedUsers.add(uid);
                  }
                }
              } else {
                for (final group in adminGroups) {
                  _selectedGroups.remove(group.id);
                  for (final uid in group.members.keys) {
                    _selectedUsers.remove(uid);
                  }
                }
              }
            });
          },
        ),
      );

      for (final group in adminGroups) {
        final allMembersSelected = group.members.keys.every(
          (uid) => _selectedUsers.contains(uid),
        );
        final groupSelected = _selectedGroups.contains(group.id);

        children.add(
          _buildGroupTile(
            name: group.name,
            memberCount: group.members.length,
            isSelected: groupSelected || allMembersSelected,
            onSelect: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedGroups.add(group.id);
                  for (final uid in group.members.keys) {
                    _selectedUsers.add(uid);
                  }
                } else {
                  _selectedGroups.remove(group.id);
                  for (final uid in group.members.keys) {
                    _selectedUsers.remove(uid);
                  }
                }
              });
            },
          ),
        );
      }
    }

    if (_filteredUsers.isEmpty) {
      children.add(
        Padding(padding: EdgeInsets.all(24), child: Text(l.noUsersFound)),
      );
    } else {
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            isRtl ? 'المستخدمين' : 'Users',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
      final allUsersSelected = _filteredUsers.every(
        (e) => _selectedUsers.contains(e.key),
      );
      children.add(
        _buildSelectAllTile(
          isSelected: allUsersSelected,
          label: allUsersSelected
              ? (isRtl ? 'إلغاء تحديد الكل' : 'Deselect all')
              : (isRtl ? 'تحديد الكل' : 'Select all'),
          onSelect: (checked) {
            setState(() {
              if (checked == true) {
                for (final entry in _filteredUsers) {
                  _selectedUsers.add(entry.key);
                }
              } else {
                for (final entry in _filteredUsers) {
                  _selectedUsers.remove(entry.key);
                }
              }
            });
          },
        ),
      );

      for (final entry in _filteredUsers) {
        children.add(_buildUserTile(entry, l));
      }
    }

    return ListView(shrinkWrap: true, children: children);
  }

  Widget _buildUserTile(MapEntry<String, AppUser> entry, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedUsers.contains(entry.key);
    final initials = entry.value.displayName.isNotEmpty
        ? entry.value.displayName[0].toUpperCase()
        : entry.value.email[0].toUpperCase();
    final avatarColors = [
      cs.primary, cs.tertiary,
      Color(0xFF7B8C6B), Color(0xFF6B7B8C),
      Color(0xFF8C6B7B), Color(0xFF8B7D6B),
    ];
    final idx = _filteredUsers.indexOf(entry);
    final color = avatarColors[idx % avatarColors.length];
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUsers.remove(entry.key);
            } else {
              _selectedUsers.add(entry.key);
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value.displayName.isNotEmpty
                          ? entry.value.displayName
                          : entry.value.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      entry.value.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllTile({
    required bool isSelected,
    required String label,
    required ValueChanged<bool?> onSelect,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelect(!isSelected),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTile({
    required String name,
    required int memberCount,
    required bool isSelected,
    required ValueChanged<bool?> onSelect,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = AppLocalizations.of(context)!.localeName == 'ar';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelect(!isSelected),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group, size: 16, color: cs.onSecondaryContainer),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isRtl
                          ? '$memberCount عضواً'
                          : '$memberCount members',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
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
}
