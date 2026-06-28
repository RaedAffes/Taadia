import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/group_model.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/models/user_model.dart';
import 'package:ta3dia/services/auth_services.dart';
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
        allUsers.sort((a, b) => a.value.displayName.compareTo(b.value.displayName));
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
            return AlertDialog(
              title: Text(l.createGroup),
              content: SizedBox(
                width: double.maxFinite,
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
                            final query = q.toLowerCase();
                            filteredUsers = allUsers
                                .where((e) =>
                                    e.value.displayName.toLowerCase().contains(query) ||
                                    e.value.email.toLowerCase().contains(query))
                                .toList();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    isLoadingUsers
                        ? Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          )
                        : filteredUsers.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(l.noUsersFound),
                              )
                            : SizedBox(
                                height: 300,
                                child: ListView(
                                  children: filteredUsers.map((entry) {
                                    final isSelected =
                                        selectedUserIds.contains(entry.key);
                                    return CheckboxListTile(
                                      value: isSelected,
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(entry.value.displayName.isNotEmpty
                                              ? entry.value.displayName
                                              : entry.value.email),
                                          Text(
                                            entry.value.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      dense: true,
                                      onChanged: (checked) {
                                        setDialogState(() {
                                          if (checked == true) {
                                            selectedUserIds.add(entry.key);
                                          } else {
                                            selectedUserIds.remove(entry.key);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.cancel),
                ),
                TextButton(
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
                            await groupService.loadGroups();
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
                  child: Text(l.create),
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
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.renameGroup),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l.groupName,
            hintText: l.groupNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteGroup),
        content: Text(l.deleteGroupConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<GroupService>(context, listen: false)
                  .deleteGroup(group.id);
            },
            child: Text(l.delete, style: TextStyle(color: Colors.red)),
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
      _allUsers.sort((a, b) => a.value.displayName.compareTo(b.value.displayName));
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
        final q = query.toLowerCase();
        _filteredUsers = _allUsers
            .where((e) =>
                e.value.displayName.toLowerCase().contains(q) ||
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.manageMembersFor(widget.group.name)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
      body: Column(
        children: [
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CheckboxListTile(
                value: allFilteredSelected,
                title: Text(l.selectAll),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      for (final e in _filteredUsers) {
                        _selectedIds.add(e.key);
                      }
                    } else {
                      for (final e in _filteredUsers) {
                        _selectedIds.remove(e.key);
                      }
                    }
                  });
                },
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
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(entry.value.displayName.isNotEmpty
                                  ? entry.value.displayName
                                  : entry.value.email),
                              Text(
                                entry.value.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(entry.key);
                              } else {
                                _selectedIds.remove(entry.key);
                              }
                            });
                          },
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
