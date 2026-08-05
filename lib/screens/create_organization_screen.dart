import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class CreateOrganizationScreen extends StatefulWidget {
  @override
  _CreateOrganizationScreenState createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final orgService = Provider.of<OrgService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? '';
    final name = auth.currentUser?.displayName ?? '';

    final orgId = await orgService.createOrganization(
      name: _nameController.text.trim(),
      password: _passwordController.text.trim(),
      creatorUid: uid,
      creatorName: name,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (orgId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إنشاء الجمعية بنجاح! بانتظار موافقة المدير العام'
                  : 'Organization created! Pending super admin approval',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orgService.errorMessage ?? 'Failed to create'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _sectionHeader(
      IconData icon, String title, String subtitle, ColorScheme cs, bool isRtl) {
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
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {required List<Widget> children, required ColorScheme cs}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 2)),
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
    final cs = Theme.of(context).colorScheme;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    final inputDecoration = (String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          hintStyle: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        );

    return AppScaffold(
      title: isRtl ? 'إنشاء جمعية' : 'Create Organization',
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
                  _sectionHeader(
                    Icons.business_outlined,
                    isRtl ? 'اسم الجمعية' : 'Organization Name',
                    isRtl
                        ? 'أدخل اسم جمعية القرآن'
                        : 'Enter the Quran association name',
                    cs,
                    isRtl,
                  ),
                  TextFormField(
                    controller: _nameController,
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    decoration: inputDecoration(
                      isRtl ? 'اسم الجمعية' : 'Organization Name',
                      isRtl
                          ? 'مثال: جمعية الرحمة'
                          : 'e.g. Al-Rahma Association',
                    ),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isRtl ? 'أدخل اسم الجمعية' : 'Enter a name')
                        : null,
                  ),
                ],
              ),
              _sectionCard(
                cs: cs,
                children: [
                  _sectionHeader(
                    Icons.lock_outline,
                    isRtl ? 'كلمة مرور الجمعية' : 'Organization Password',
                    isRtl
                        ? 'يجب على الأعضاء إدخالها للانضمام'
                        : 'Members must enter this to join',
                    cs,
                    isRtl,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    decoration: inputDecoration(
                      isRtl ? 'كلمة المرور' : 'Password',
                      isRtl
                          ? 'أدخل كلمة مرور للجمعية'
                          : 'Enter a password for the organization',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    style: TextStyle(fontSize: 15),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return isRtl
                            ? 'أدخل كلمة المرور'
                            : 'Enter a password';
                      if (v.trim().length < 4)
                        return isRtl
                            ? '4 أحرف على الأقل'
                            : 'At least 4 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    decoration: inputDecoration(
                      isRtl ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      isRtl
                          ? 'أعد إدخال كلمة المرور'
                          : 'Re-enter the password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    style: TextStyle(fontSize: 15),
                    validator: (v) {
                      if (v != _passwordController.text)
                        return isRtl
                            ? 'كلمتا المرور غير متطابقتين'
                            : 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.tertiary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: cs.tertiary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isRtl
                            ? 'ستظهر الجمعية للمدير العام للموافقة عليها. بعد الموافقة، تصبح المشرف)'
                            : 'The organization will appear for super admin approval. Once approved, you become the admin.',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor:
                        cs.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_business_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                                isRtl
                                    ? 'إنشاء الجمعية'
                                    : 'Create Organization',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed:
                      _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isRtl ? 'العودة' : 'Go Back',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
