import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/user_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/string_utils.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class ManageUsersScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<AppUser> _users = [];
  final _searchController = TextEditingController();
  bool _loading = true;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'manage_users_screen');
    });
    _authService = Provider.of<AuthService>(context, listen: false);
    _authService!.addListener(_onAuthChange);
    _loadUsers();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final all = authService.allUsers;
      final query = normalizeArabic(_searchController.text.trim().toLowerCase());
      setState(() {
        _users = query.isEmpty
            ? all
            : all
                  .where(
                    (u) =>
                        normalizeArabic(u.displayName.toLowerCase()).contains(query) ||
                        u.email.toLowerCase().contains(query),
                  )
                  .toList();
        _sortUsers(_users);
        _loading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = authService.allUsers;
        _sortUsers(_users);
        _loading = false;
      });
    }
  }

  static void _sortUsers(List<AppUser> users) {
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _searchUser() {
    final query = normalizeArabic(_searchController.text.trim().toLowerCase());
    final authService = Provider.of<AuthService>(context, listen: false);
    final all = authService.allUsers;
    if (query.isEmpty) {
      setState(() {
        _users = all;
        _sortUsers(_users);
      });
    } else {
      setState(() {
        _users = all
            .where(
              (u) =>
                  normalizeArabic(u.displayName.toLowerCase()).contains(query) ||
                  u.email.toLowerCase().contains(query),
            )
            .toList();
        _sortUsers(_users);
      });
    }
  }

  Future<void> _toggleRole(AppUser user) async {
    final l = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUid = authService.currentUser?.uid ?? '';
    if (user.isAdmin) {
      if (user.uid == currentUid) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.cannotDemoteSelf),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
      if (user.promotedBy.isNotEmpty && user.promotedBy != currentUid) {
        final promoterName = _users
            .where((u) => u.uid == user.promotedBy)
            .firstOrNull
            ?.displayName;
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.onlyPromoterCanDemote(promoterName ?? 'Unknown')),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
    }
    final newRole = user.isAdmin ? 'user' : 'admin';
    widget.analytics.logEvent(
      name: 'toggle_user_role',
      parameters: {
        'user_id': user.uid,
        'user_name': user.displayName,
        'new_role': newRole,
        'previous_role': user.isAdmin ? 'admin' : 'user',
      },
    );
    final ok = await authService.setUserRole(
      user.uid,
      newRole,
      promoterUid: newRole == 'admin' ? currentUid : null,
    );
    if (ok) await _loadUsers();
  }

  Future<void> _deleteUser(AppUser user) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (user.uid ==
        Provider.of<AuthService>(context, listen: false).currentUser?.uid) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.cannotDeleteSelf),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    widget.analytics.logEvent(
      name: 'delete_user',
      parameters: {
        'user_id': user.uid,
        'user_name': user.displayName,
      },
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error, size: 22),
            SizedBox(width: 8),
            Text(l.deleteUserTitle, style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(l.deleteUserConfirm(user.displayName), style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final deleted = await authService.deleteUser(user.uid);
      if (deleted) await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AppScaffold(
      title: l.manageUsers,
      actions: [
        IconButton(
          icon: Icon(Icons.dashboard),
          tooltip: l.taadiaManagement,
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: cs.surfaceContainerHighest,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchUser(),
              decoration: InputDecoration(
                hintText: l.searchByName,
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: cs.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          if (!_loading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: cs.onSurfaceVariant),
                  SizedBox(width: 6),
                  Text(
                    '${_users.length} ${l.user}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 40, color: cs.onSurfaceVariant),
                        SizedBox(height: 8),
                        Text(l.noUsersFound, style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
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
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: user.isAdmin
                                ? cs.primary.withValues(alpha: 0.3)
                                : cs.outlineVariant.withValues(alpha: 0.4),
                            width: user.isAdmin ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withValues(alpha: 0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    user.isAdmin ? Icons.shield : Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: cs.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.isAdmin ? l.admin : l.user,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: user.isAdmin
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              _smallIconBtn(
                                user.isAdmin
                                    ? Icons.person_remove
                                    : Icons.person_add,
                                user.isAdmin ? l.removeAdmin : l.makeAdmin,
                                () => _toggleRole(user),
                                cs,
                              ),
                              _smallIconBtn(
                                Icons.delete_outline,
                                l.deleteUser,
                                () => _deleteUser(user),
                                cs,
                                isError: true,
                              ),
                            ],
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

  Widget _smallIconBtn(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    ColorScheme cs, {
    bool isError = false,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(
          icon,
          size: 18,
          color: isError ? cs.error : cs.onSurfaceVariant,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
