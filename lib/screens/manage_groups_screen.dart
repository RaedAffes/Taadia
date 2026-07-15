import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/group_model.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/models/user_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/string_utils.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class ManageGroupsScreen extends StatefulWidget {
  @override
  _ManageGroupsScreenState createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends State<ManageGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupService>(context, listen: false).loadGroups();
    });
  }

  void _showCreateDialog() {
    final l = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final searchController = TextEditingController();
    List<MapEntry<String, AppUser>> allUsers = [];
    List<MapEntry<String, AppUser>> filteredUsers = [];
    Set<String> selectedUserIds = {};
    bool isLoadingUsers = true;
    bool isCreating = false;

    Future<void> loadUsers(StateSetter setDialogState) async {
      setDialogState(() => isLoadingUsers = true);
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final users = await auth.getAllUsers();
        allUsers = users
            .where((u) => !u.isAdmin)
            .map((u) => MapEntry(u.uid, u))
            .toList();
        allUsers.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
        filteredUsers = List.from(allUsers);
      } catch (e) {
        filteredUsers = [];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l.failedToCreate}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setDialogState(() => isLoadingUsers = false);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isLoadingUsers) {
              loadUsers(setDialogState);
            }
            final cs = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.group_add, size: 20, color: cs.onPrimaryContainer),
                  ),
                  SizedBox(width: 10),
                  Text(l.createGroup, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l.groupName,
                          hintText: l.groupNameHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: l.searchByName,
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (q) {
                          setDialogState(() {
                            if (q.isEmpty) {
                              filteredUsers = List.from(allUsers);
                            } else {
                              final query = normalizeArabic(q.toLowerCase());
                              filteredUsers = allUsers
                                  .where((e) =>
                                      normalizeArabic(e.value.displayName.toLowerCase()).contains(query) ||
                                      e.value.email.toLowerCase().contains(query))
                                  .toList();
                            }
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: isLoadingUsers
                            ? Center(child: CircularProgressIndicator())
                            : filteredUsers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people_outline, size: 36, color: cs.onSurfaceVariant),
                                        SizedBox(height: 8),
                                        Text(l.noUsersFound, style: TextStyle(color: cs.onSurfaceVariant)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final entry = filteredUsers[index];
                                      final isSelected = selectedUserIds.contains(entry.key);
                                      final initials = entry.value.displayName.isNotEmpty
                                          ? entry.value.displayName[0].toUpperCase()
                                          : entry.value.email[0].toUpperCase();
                                      final avatarColors = [
                                        cs.primary, cs.tertiary,
                                        Color(0xFF7B8C6B), Color(0xFF6B7B8C),
                                        Color(0xFF8C6B7B), Color(0xFF8B7D6B),
                                      ];
                                      final color = avatarColors[index % avatarColors.length];
                                      return AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? cs.primaryContainer.withValues(alpha: 0.4)
                                              : cs.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? cs.primary.withValues(alpha: 0.6)
                                                : cs.outlineVariant.withValues(alpha: 0.4),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            setDialogState(() {
                                              if (isSelected) {
                                                selectedUserIds.remove(entry.key);
                                              } else {
                                                selectedUserIds.add(entry.key);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
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
                                                        fontSize: 15,
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
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        entry.value.email,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: cs.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                AnimatedContainer(
                                                  duration: Duration(milliseconds: 200),
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? cs.primary : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? cs.primary
                                                          : cs.outlineVariant,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => isCreating = true);
                          final groupService = Provider.of<GroupService>(
                              context,
                              listen: false);
                          final id =
                              await groupService.createGroup(name);
                          if (mounted && id != null) {
                            for (final uid in selectedUserIds) {
                              await groupService.addMember(id, uid);
                            }
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.done),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (mounted) {
                            setDialogState(() => isCreating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(groupService.errorMessage ??
                                    l.failedToCreate),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: isCreating
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                      : Text(l.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(GroupModel group) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit, size: 20, color: cs.onPrimaryContainer),
            ),
            SizedBox(width: 10),
            Text(l.renameGroup, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l.groupName,
            hintText: l.groupNameHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty || name == group.name) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              await Provider.of<GroupService>(context, listen: false)
                  .updateGroupName(group.id, name);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showManageMembers(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ManageGroupMembersScreen(group: group),
      ),
    );
  }

  void _showDeleteConfirm(GroupModel group) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error, size: 22),
            SizedBox(width: 8),
            Text(l.deleteGroup, style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(l.deleteGroupConfirm(group.name), style: TextStyle(height: 1.5)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<GroupService>(context, listen: false)
                  .deleteGroup(group.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final groupService = context.watch<GroupService>();

    return AppScaffold(
      title: l.manageGroups,
      body: groupService.isLoading
          ? Center(child: CircularProgressIndicator())
          : groupService.groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_work, size: 64, color: cs.outlineVariant),
                      SizedBox(height: 16),
                      Text(
                        l.noGroupsYet,
                        style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
                      ),
                      SizedBox(height: 8),
                      Text(
                        l.tapToCreateGroup,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => groupService.loadGroups(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: groupService.groups.length,
                    itemBuilder: (context, index) {
                      final g = groupService.groups[index];
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => _showManageMembers(g),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.group,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                          title: Text(
                            g.name,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l.groupMemberCount(g.memberCount),
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: l.renameGroup,
                                onPressed: () => _showRenameDialog(g),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20),
                                tooltip: l.deleteGroup,
                                color: cs.error,
                                onPressed: () => _showDeleteConfirm(g),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: Icon(Icons.add),
        tooltip: l.createGroup,
      ),
    );
  }
}

class _ManageGroupMembersScreen extends StatefulWidget {
  final GroupModel group;
  const _ManageGroupMembersScreen({required this.group});

  @override
  __ManageGroupMembersScreenState createState() =>
      __ManageGroupMembersScreenState();
}

class __ManageGroupMembersScreenState
    extends State<_ManageGroupMembersScreen> {
  List<MapEntry<String, AppUser>> _allUsers = [];
  List<MapEntry<String, AppUser>> _filteredUsers = [];
  final _searchController = TextEditingController();
  bool _isLoadingUsers = true;
  String? _loadError;
  Set<String> _selectedIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelectedIds();
  }

  void _syncSelectedIds() {
    final groupService = Provider.of<GroupService>(context, listen: false);
    final currentGroup = groupService.groups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );
    _selectedIds = Set.from(currentGroup.members.keys);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _loadError = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final users = await auth.getAllUsers();
      _allUsers = users
          .where((u) => !u.isAdmin)
          .map((u) => MapEntry(u.uid, u))
          .toList();
      _allUsers.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
      _filteredUsers = List.from(_allUsers);
      _syncSelectedIds();
    } catch (e) {
      _loadError = e.toString();
      _allUsers = [];
      _filteredUsers = [];
    }
    if (mounted) setState(() => _isLoadingUsers = false);
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final q = normalizeArabic(query.toLowerCase());
        _filteredUsers = _allUsers
            .where((e) =>
                normalizeArabic(e.value.displayName.toLowerCase()).contains(q) ||
                e.value.email.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final groupService = Provider.of<GroupService>(context, listen: false);
    final currentGroup = groupService.groups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );
    final currentMembers = currentGroup.members;
    final l = AppLocalizations.of(context)!;

    for (final uid in _selectedIds) {
      if (!currentMembers.containsKey(uid)) {
        await groupService.addMember(widget.group.id, uid);
      }
    }
    for (final uid in currentMembers.keys) {
      if (!_selectedIds.contains(uid)) {
        await groupService.removeMember(widget.group.id, uid);
      }
    }
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.done), backgroundColor: Colors.green),
      );
    }
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
    final allFilteredSelected = _filteredUsers.isNotEmpty &&
        _filteredUsers.every((e) => _selectedIds.contains(e.key));

    return AppScaffold(
      title: l.manageMembersFor(widget.group.name),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                  )
                : Icon(Icons.save_rounded, size: 18),
            label: Text(l.save),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.group, size: 18, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  widget.group.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l.searchByName,
                hintText: l.search,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          if (!_isLoadingUsers && _loadError == null && _filteredUsers.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: allFilteredSelected
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: allFilteredSelected
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (allFilteredSelected) {
                      for (final e in _filteredUsers) {
                        _selectedIds.remove(e.key);
                      }
                    } else {
                      for (final e in _filteredUsers) {
                        _selectedIds.add(e.key);
                      }
                    }
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: allFilteredSelected ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: allFilteredSelected ? cs.primary : cs.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: allFilteredSelected
                            ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                            : null,
                      ),
                      SizedBox(width: 10),
                      Text(
                        l.selectAll,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoadingUsers
                ? Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            '${l.failedToCreate}: $_loadError',
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      l.noUsersFound,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredUsers[index];
                      final isSelected = _selectedIds.contains(entry.key);
                      final initials = entry.value.displayName.isNotEmpty
                          ? entry.value.displayName[0].toUpperCase()
                          : entry.value.email[0].toUpperCase();
                      final avatarColors = [
                        cs.primary, cs.tertiary,
                        Color(0xFF7B8C6B), Color(0xFF6B7B8C),
                        Color(0xFF8C6B7B), Color(0xFF8B7D6B),
                      ];
                      final color = avatarColors[index % avatarColors.length];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer.withValues(alpha: 0.4)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.6)
                                : cs.outlineVariant.withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(entry.key);
                              } else {
                                _selectedIds.add(entry.key);
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
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
                                        fontSize: 15,
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
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        entry.value.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected ? cs.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.outlineVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
