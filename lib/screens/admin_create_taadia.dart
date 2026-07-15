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
  String? _codeError;
  final _categoryInputController = TextEditingController();
  final List<String> _categories = [];
  final List<ClassificationConfig> _classifications = [];
  final List<TextEditingController> _classificationOptionControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taadiaService = Provider.of<TaadiaService>(context, listen: false);
      Provider.of<GroupService>(context, listen: false).loadGroups();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final groupService = context.watch<GroupService>();
    final isRtl = l.localeName == 'ar';

    return AppScaffold(
      title: l.createTaadia,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l.assessmentTitle,
                  hintText: l.titleHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.enterTitle : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.descriptionOptional,
                  hintText: l.descriptionHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 24),
              Text(
                isRtl ? 'التصنيفات' : 'Classifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isRtl
                    ? 'أضف تصنيفات لتقسيم الطلاب (اختياري)'
                    : 'Add classifications to describe the student (optional)',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              SizedBox(height: 12),
              ...List.generate(_classifications.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _classificationOptionControllers[i],
                                decoration: InputDecoration(
                                  hintText: isRtl
                                      ? ' مثال: نخبة 1 ...'
                                      : 'Add a classification...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addClassificationOption(i),
                              ),
                            ),
                            SizedBox(width: 6),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                              ),
                              onPressed: () => _addClassificationOption(i),
                              child: Icon(Icons.add, size: 18),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              tooltip: isRtl
                                  ? 'حذف التصنيف'
                                  : 'Remove classification',
                              onPressed: () => _removeClassification(i),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (_classifications[i].options.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: _classifications[i].options
                                  .asMap()
                                  .entries
                                  .map((optEntry) {
                                    return Chip(
                                      label: Text(
                                        optEntry.value,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      deleteIcon: Icon(Icons.close, size: 14),
                                      onDeleted: () =>
                                          _removeClassificationOption(
                                            i,
                                            optEntry.key,
                                          ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addClassification,
                icon: Icon(Icons.add, size: 18),
                label: Text(isRtl ? 'أضف تصنيفاً' : 'Add classification'),
              ),
              SizedBox(height: 24),
              Text(
                l.accessControl,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                l.accessControlDesc,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_selectedUserIds.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_selectedUserIds.length} ${l.usersSelected.toLowerCase()}',
                          style: TextStyle(color: cs.primary),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.person_add, size: 18),
                          label: Text(l.selectUsers),
                          onPressed: _showUserPicker,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                l.accessCode,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                l.accessCodeDesc,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    l.autoGenerate,
                    style: TextStyle(fontSize: 15, color: cs.onSurface),
                  ),
                  SizedBox(width: 8),
                  Switch(
                    value: !_isManualCode,
                    onChanged: (v) {
                      setState(() {
                        _isManualCode = !v;
                        _codeError = null;
                        if (_isManualCode) {
                          _accessCodeController.text = _manualCode.isNotEmpty
                              ? _manualCode
                              : _accessCode;
                        } else {
                          _manualCode = _accessCodeController.text;
                        }
                      });
                    },
                  ),
                  if (_isManualCode)
                    Text(
                      l.enterManually,
                      style: TextStyle(fontSize: 15, color: cs.onSurface),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (_isManualCode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: cs.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _accessCodeController,
                          decoration: InputDecoration(
                            hintText: l.accessCodeHint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            counterText: '',
                            hintStyle: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: cs.primary,
                          ),
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
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: cs.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          _accessCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        tooltip: l.copy,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _accessCode));
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(l.copied)));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: l.regenerateCode,
                        onPressed: _regenerateCode,
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  child: _loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(l.create, style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: Text(l.goBack, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
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
    Provider.of<GroupService>(context, listen: false).loadGroups();
    final users = await auth.getAllUsers();
    _allUsers = users
        .where((u) => !u.isAdmin)
        .map((u) => MapEntry(u.uid, u))
        .toList();
    _allUsers.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
    _filteredUsers = List.from(_allUsers);
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
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l.selectUsers,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchByName,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDone(_selectedGroups, _selectedUsers);
                  Navigator.pop(context);
                },
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

    final groupService = context.watch<GroupService>();
    final adminGroups = groupService.groups
        .where((g) => g.createdBy == _currentUid)
        .toList();

    if (_filteredUsers.isEmpty) {
      children.add(
        Padding(padding: EdgeInsets.all(24), child: Text(l.noUsersFound)),
      );
    } else {
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
          CheckboxListTile(
            dense: true,
            value: allGroupsSelected,
            title: Text(
              allGroupsSelected
                  ? (isRtl ? 'إلغاء تحديد الكل' : 'Deselect all')
                  : (isRtl ? 'تحديد الكل' : 'Select all'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onChanged: (checked) {
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
          final anyInFilter = group.members.keys.any(
            (uid) => _filteredUsers.any((e) => e.key == uid),
          );
          if (!anyInFilter) continue;

          final allMembersSelected = group.members.keys.every(
            (uid) => _selectedUsers.contains(uid),
          );
          final groupSelected = _selectedGroups.contains(group.id);

          children.add(
            CheckboxListTile(
              dense: true,
              value: groupSelected || allMembersSelected,
              title: Text(
                group.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${group.members.length} ${isRtl ? 'عضواً' : 'members'}',
                style: TextStyle(fontSize: 11),
              ),
              onChanged: (checked) {
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
        CheckboxListTile(
          dense: true,
          value: allUsersSelected,
          title: Text(
            allUsersSelected
                ? (isRtl ? 'إلغاء تحديد الكل' : 'Deselect all')
                : (isRtl ? 'تحديد الكل' : 'Select all'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          onChanged: (checked) {
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
    return CheckboxListTile(
      dense: true,
      value: _selectedUsers.contains(entry.key),
      title: Text(
        entry.value.displayName.isNotEmpty
            ? entry.value.displayName
            : entry.value.email,
        style: TextStyle(fontSize: 14),
      ),
      subtitle: Text(entry.value.email, style: TextStyle(fontSize: 11)),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedUsers.add(entry.key);
          } else {
            _selectedUsers.remove(entry.key);
          }
        });
      },
    );
  }
}
