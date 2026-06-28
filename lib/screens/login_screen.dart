import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/providers/app_state.dart';
import 'package:ta3dia/screens/register_screen.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/google_logo.dart';
import 'package:ta3dia/widgets/taadia_background.dart';

class LoginScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      widget.analytics.logEvent(
        name: 'sign_in_attempt',
        parameters: {
          'method': 'email_password',
          'email': _emailController.text.trim(),
        },
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    widget.analytics.logEvent(name: 'sign_in_attempt', parameters: {
      'method': 'google',
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();
    if (!success && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? l.googleSignInFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInAnonymously() async {
    widget.analytics.logEvent(name: 'sign_in_attempt', parameters: {
      'method': 'anonymous',
    });
    final l = AppLocalizations.of(context)!;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (ctx) {
        final dlgCs = Theme.of(ctx).colorScheme;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: Text(l.welcomeGuest),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.enterNameDesc,
                    style: TextStyle(
                      color: dlgCs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l.yourName,
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: dlgCs.surfaceContainerHighest,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (v) {
                      final trimmed = v.trim();
                      if (trimmed.isEmpty) {
                        setDlgState(() => errorText = l.enterYourName);
                      } else {
                        Navigator.pop(ctx, trimmed);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final trimmed = nameController.text.trim();
                    if (trimmed.isEmpty) {
                      setDlgState(() => errorText = l.enterYourName);
                    } else {
                      Navigator.pop(ctx, trimmed);
                    }
                  },
                  child: Text(l.continueLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (name == null || name.trim().isEmpty || !mounted) return;

    widget.analytics.setUserProperty(name: 'guest_name', value: name.trim());
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signInAnonymously(displayName: name.trim());
  }

  void _resetPassword() {
    final l = AppLocalizations.of(context)!;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    showDialog(
      context: context,
      builder: (ctx) {
        String? emailError;
        bool sending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dlgCs = Theme.of(context).colorScheme;
            final resetController = TextEditingController();
            return AlertDialog(
              title: Text(l.resetPassword),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.resetPasswordDesc,
                    style: TextStyle(
                      color: dlgCs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l.email,
                      errorText: emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: dlgCs.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(ctx),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = resetController.text.trim();
                          if (email.isEmpty || !emailRegex.hasMatch(email)) {
                            setDialogState(() => emailError = l.invalidEmail);
                            return;
                          }
                          setDialogState(() {
                            emailError = null;
                            sending = true;
                          });
                          final authService = Provider.of<AuthService>(
                            this.context,
                            listen: false,
                          );
                          authService.clearError();
                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(this.context);
                          final success = await authService.resetPassword(
                            email,
                          );
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? l.resetLinkSent(email)
                                      : authService.errorMessage ??
                                            l.failedToSendReset,
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        },
                  child: sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.sendResetLink),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'login_screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.appName),
              content: Text(l.exitConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.exit, style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (exit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
      body: TaadiaBackground(
        backgroundImage: 'assets/images/app logo.png',
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 48),
                    TaadiaHeader(
                      title: l.appName,
                      subtitle: l.signUpSubtitle,
                      imageHeight: 100,
                      imagePath: 'assets/images/app logo.png',
                    ),
                    SizedBox(height: 32),
                    TaadiaFormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l.email,
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return l.enterEmail;
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(v))
                                  return l.invalidEmail;
                                return null;
                              },
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l.password,
                                prefixIcon: Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return l.enterPassword;
                                return null;
                              },
                            ),
                            SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                child: Text(
                                  l.forgotPassword,
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Consumer<AuthService>(
                              builder: (context, authService, child) {
                                final errMsg =
                                    authService.localizedError(l) ??
                                    authService.errorMessage;
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: authService.isLoading
                                            ? null
                                            : _signIn,
                                        child: authService.isLoading
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                l.signIn,
                                                style: TextStyle(fontSize: 16),
                                              ),
                                      ),
                                    ),
                                    if (errMsg != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                          errMsg,
                                          style: TextStyle(
                                            color: cs.error,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l.orContinueWith,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildGoogleButton(onTap: _signInWithGoogle, cs: cs),
                    SizedBox(height: 10),
                    _buildSocialButton(
                      icon: Icons.person_outline,
                      label: l.continueAsGuest,
                      color: cs.onSurfaceVariant,
                      onTap: _signInAnonymously,
                      cs: cs,
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l.dontHaveAccount + ' ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.analytics.logEvent(
                              name: 'navigate_to_register',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegisterScreen()),
                            );
                          },
                          child: Text(
                            l.signUp,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<AppState>(
                  builder: (context, state, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            state.setLanguage(
                              state.locale.languageCode == 'en' ? 'ar' : 'en',
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 400),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(
                                key: ValueKey(state.locale.languageCode),
                                state.locale.languageCode == 'en' ? 'AR' : 'EN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => state.toggleTheme(),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  RotationTransition(
                                    turns: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Icon(
                                key: ValueKey(state.isDark),
                                state.isDark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                size: 16,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: cs.onSurface)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: cs.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleLogo(),
            SizedBox(width: 12),
            Text('Google', style: TextStyle(color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
