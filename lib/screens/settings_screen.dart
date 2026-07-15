import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/providers/app_state.dart';
import 'package:ta3dia/screens/login_screen.dart';

import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'settings_screen');
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameController.text = auth.appUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);
    final l = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.updateProfile(
      displayName: _nameController.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? l.profileUpdated : l.updateFailed),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.currentUser?.email;
    if (email == null) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    auth.clearError();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.resetPassword(email);
    if (mounted) {
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l.resetLinkSent(email)
                : auth.errorMessage ?? l.failedToSendReset,
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    Navigator.of(context).popUntil((route) => route.isFirst);
    await auth.signOut();
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthService>(context, listen: false);
    final provider = auth.appUser?.authProvider ?? 'email';
    final isEmailUser = provider == 'email';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccountConfirm),
        content: Text(l.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAccount, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    var ok = await auth.deleteAccount();

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.accountDeleted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
      return;
    }

    if (auth.errorCode == 'requires-recent-login') {
      if (isEmailUser) {
        final passwordController = TextEditingController();
        final password = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.deleteAccount),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l.password,
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, passwordController.text),
                child: Text(
                  l.deleteAccount,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        passwordController.dispose();
        if (password == null || password.isEmpty) {
          if (mounted) setState(() => _loading = false);
          return;
        }
        ok = await auth.reauthenticateAndDelete(password: password);
      } else {
        ok = await auth.reauthenticateAndDelete();
      }

      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.accountDeleted),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        }
      } else if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? l.updateFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? l.updateFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthService>(context);
    final provider = auth.appUser?.authProvider ?? 'email';
    final isEmailUser = provider == 'email';

    return AppScaffold(
      title: l.settings,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.profile,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l.displayName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          auth.currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () {
                        widget.analytics.logEvent(
                          name: 'update_profile',
                          parameters: {
                            'display_name': _nameController.text.trim(),
                          },
                        );
                        _updateProfile();
                      },
                      child: _loading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(l.saveChanges),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Consumer<AppState>(
            builder: (context, state, _) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      state.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: cs.primary,
                    ),
                    title: Text(
                      state.isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(color: cs.onSurface),
                    ),
                    value: state.isDark,
                    activeColor: cs.primary,
                    onChanged: (_) => state.toggleTheme(),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.language, color: cs.primary),
                    title: Text(
                      state.locale.languageCode == 'en' ? 'English' : 'العربية',
                      style: TextStyle(color: cs.onSurface),
                    ),
                    trailing: Text(
                      state.locale.languageCode == 'en' ? 'EN' : 'AR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    onTap: () {
                      state.setLanguage(
                        state.locale.languageCode == 'en' ? 'ar' : 'en',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isEmailUser) ...[
            SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.lock_reset, color: cs.primary),
                title: Text(
                  l.resetPassword,
                  style: TextStyle(color: cs.onSurface),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                onTap: () {
                  widget.analytics.logEvent(
                    name: 'reset_password',
                  );
                  _resetPassword();
                },
              ),
            ),
          ],
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: cs.error),
              title: Text(l.logout, style: TextStyle(color: cs.error)),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              onTap: () {
                widget.analytics.logEvent(
                  name: 'logout',
                );
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.logout),
                    content: Text(l.areYouSure),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _signOut();
                        },
                        child: Text(
                          l.logout,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: cs.error),
              title: Text(l.deleteAccount, style: TextStyle(color: cs.error)),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              onTap: _loading ? null : () {
                widget.analytics.logEvent(
                  name: 'delete_account',
                );
                _deleteAccount();
              },
            ),
          ),
        ],
      ),
    );
  }
}
