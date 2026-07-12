import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/google_logo.dart';
import 'package:ta3dia/widgets/taadia_background.dart';

class RegisterScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'register_screen');
    });
  }

  Future<void> _signUp() async {
    widget.analytics.logEvent(
      name: 'sign_up_attempt',
      parameters: {
        'email': _emailController.text.trim(),
        'display_name': _nameController.text.trim(),
      },
    );
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (success && mounted) {
        widget.analytics.logEvent(
          name: 'sign_up_success',
          parameters: {
            'email': _emailController.text.trim(),
            'display_name': _nameController.text.trim(),
          },
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    widget.analytics.logEvent(
      name: 'sign_up_attempt',
      parameters: {
        'method': 'google',
      },
    );
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();
    if (success && mounted) {
      widget.analytics.logEvent(
        name: 'sign_up_success',
        parameters: {
          'method': 'google',
        },
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.createAccount),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        actions: const [],
      ),
      body: TaadiaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8),
                TaadiaHeader(
                  title: l.joinTaadia,
                  subtitle: l.signUpSubtitle,
                ),
                SizedBox(height: 28),
                TaadiaFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          SizedBox(width: 8),
                          Text(
                            l.signUpWithEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: l.fullName,
                                prefixIcon: Icon(Icons.person_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? l.enterYourName
                                  : null,
                            ),
                            SizedBox(height: 14),
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
                                  return l.enterAPassword;
                                if (v.length < 6) return l.atLeast6Chars;
                                return null;
                              },
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: l.confirmPassword,
                                prefixIcon: Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return l.confirmYourPassword;
                                if (v != _passwordController.text)
                                  return l.passwordsDoNotMatch;
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
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
                                            : _signUp,
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
                                                l.createAccount,
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
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l.orSignUpWith,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 24),
                _buildGoogleButton(onTap: _signInWithGoogle, cs: cs),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.alreadyHaveAccount + ' ',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.analytics.logEvent(
                          name: 'navigate_to_login',
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        l.signIn,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
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
