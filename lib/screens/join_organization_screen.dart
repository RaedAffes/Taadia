import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class JoinOrganizationScreen extends StatefulWidget {
  @override
  _JoinOrganizationScreenState createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  bool _loading = true;
  String? _selectedOrgId;
  String? _selectedOrgName;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrgs());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadOrgs() async {
    final orgService = Provider.of<OrgService>(context, listen: false);
    await orgService.loadApprovedOrgs();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _join() async {
    if (_selectedOrgId == null) return;
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'أدخل كلمة المرور'
                  : 'Enter the password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _joining = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final orgService = Provider.of<OrgService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? '';
    final userName = auth.currentUser?.displayName ?? '';

    final success = await orgService.joinOrganization(
      orgId: _selectedOrgId!,
      password: password,
      uid: uid,
      userName: userName,
    );

    if (mounted) {
      setState(() => _joining = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم الانضمام بنجاح!'
                  : 'Joined successfully!',
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
            content: Text(orgService.errorMessage ?? 'Failed to join'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final orgService = context.watch<OrgService>();

    return AppScaffold(
      title: isRtl ? 'الانضمام لجمعية' : 'Join Organization',
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : orgService.allApprovedOrgs.isEmpty
              ? _buildEmptyState(cs, isRtl)
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl
                            ? 'اختر جمعية و أدخل كلمة المرور للانضمام'
                            : 'Select an organization and enter the password to join',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 20),
                      ...orgService.allApprovedOrgs.map((org) {
                        final isSelected = _selectedOrgId == org.id;
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primaryContainer.withValues(alpha: 0.4)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary.withValues(alpha: 0.6)
                                  : cs.outlineVariant.withValues(alpha: 0.4),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _selectedOrgId = org.id;
                                  _selectedOrgName = org.name;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            cs.primary,
                                            cs.primary.withValues(alpha: 0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          org.name.isNotEmpty
                                              ? org.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            org.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            isRtl
                                                ? '${org.memberCount} أعضاء'
                                                : '${org.memberCount} members',
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
                                        color: isSelected
                                            ? cs.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? cs.primary
                                              : cs.outlineVariant,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_selectedOrgId != null) ...[
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock_outline,
                                      size: 18, color: cs.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    isRtl
                                        ? 'كلمة مرور "$_selectedOrgName"'
                                        : 'Password for "$_selectedOrgName"',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: isRtl
                                      ? 'أدخل كلمة المرور'
                                      : 'Enter the password',
                                  filled: true,
                                  fillColor: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: cs.primary, width: 1.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                style: TextStyle(fontSize: 15),
                                onFieldSubmitted: (_) => _join(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_selectedOrgId != null && !_joining)
                              ? _join
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            disabledBackgroundColor:
                                cs.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _joining
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.group_add_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                        isRtl
                                            ? 'انضم للجمعية'
                                            : 'Join Organization',
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
                          onPressed: _joining
                              ? null
                              : () => Navigator.pop(context),
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
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isRtl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: cs.outlineVariant),
          SizedBox(height: 16),
          Text(
            isRtl
                ? 'لا توجد جمعيات متاحة'
                : 'No organizations available',
            style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 8),
          Text(
            isRtl
                ? 'لم تتم الموافقة على أي جمعية بعد'
                : 'No organizations have been approved yet',
            style: TextStyle(fontSize: 13, color: cs.outlineVariant),
          ),
        ],
      ),
    );
  }
}
