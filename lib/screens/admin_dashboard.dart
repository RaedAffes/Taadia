import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/screens/admin_create_taadia.dart';
import 'package:ta3dia/screens/admin_manage_users.dart';
import 'package:ta3dia/screens/admin_taadia_results.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/pdf_service.dart';
import 'package:ta3dia/models/taadia_model.dart';

class AdminDashboard extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'admin_dashboard');
      Provider.of<TaadiaService>(context, listen: false).loadTaadias();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final authService = Provider.of<AuthService>(context);
    final taadiaService = Provider.of<TaadiaService>(context);
    final visibleTaadias = taadiaService.taadias
        .where((t) => t.visibility != 'private')
        .toList();

    return AppScaffold(
      title: l.taadiaManagement,
      actions: [
        IconButton(
          icon: Icon(Icons.people),
          tooltip: l.manageUsers,
          onPressed: () {
            widget.analytics.logEvent(
              name: 'navigate_to_manage_users',
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManageUsersScreen()),
            );
          },
        ),
      ],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: cs.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.welcomeAdmin(authService.appUser?.displayName ?? 'Admin'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l.manageYourTaadias,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: taadiaService.isLoading && visibleTaadias.isEmpty
                ? Center(child: CircularProgressIndicator())
                : visibleTaadias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: cs.outlineVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l.noTaadiasYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          l.tapToCreateFirst,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => taadiaService.loadTaadias(),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: visibleTaadias.length,
                      itemBuilder: (context, index) {
                        final t = visibleTaadias[index];
                        return Card(
                          elevation: 1,
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              widget.analytics.logEvent(
                                name: 'admin_taadia_clicked',
                                parameters: {
                                  'taadia_id': t.id,
                                  'taadia_title': t.title,
                                },
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminTaadiaResults(taadia: t),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Image.asset(
                                          'assets/images/quran image.png',
                                          height: 24,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.assignment,
                                            color: cs.onPrimaryContainer,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: cs.onSurface,
                                              ),
                                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: t.status == 'active'
                                                        ? cs.tertiaryContainer
                                                        : cs.surfaceContainerHighest,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    t.status == 'active'
                                                        ? l.open
                                                        : l.close,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          t.status == 'active'
                                                          ? cs.onTertiaryContainer
                                                          : cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    t.description.isNotEmpty
                                                        ? t.description
                                                        : '',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (t.accessCode.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: t.accessCode));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(l.copied), duration: Duration(seconds: 1)),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: cs.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.vpn_key, size: 12, color: cs.primary),
                                                SizedBox(width: 4),
                                                Text(
                                                  t.accessCode,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: cs.primary,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Spacer(),
                                      _iconBtn(
                                        Icons.rate_review,
                                        l.evaluate,
                                        () {
                                          if (t.status != 'active') {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppLocalizations.of(context)!.taadiaClosed),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          widget.analytics.logEvent(
                                            name: 'admin_evaluate_taadia',
                                            parameters: {
                                              'taadia_id': t.id,
                                              'taadia_title': t.title,
                                            },
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EvaluateScreen(
                                                taadiaId: t.id,
                                                taadiaTitle: t.title,
                                                taadiaDescription: t.description,
                                                classifications: t.classifications,
                                              ),
                                            ),
                                          );
                                        },
                                        cs,
                                      ),
                                      _iconBtn(
                                        Icons.visibility,
                                        AppLocalizations.of(
                                          context,
                                        )!.results,
                                        () {
                                          widget.analytics.logEvent(
                                            name: 'admin_view_taadia_results',
                                            parameters: {
                                              'taadia_id': t.id,
                                              'taadia_title': t.title,
                                            },
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminTaadiaResults(
                                                    taadia: t,
                                                  ),
                                            ),
                                          );
                                        },
                                        cs,
                                      ),
                                      _iconBtn(
                                        Icons.download,
                                        'Download PDF',
                                        () {
                                          widget.analytics.logEvent(
                                            name: 'admin_download_taadia_pdf',
                                            parameters: {
                                              'taadia_id': t.id,
                                              'taadia_title': t.title,
                                            },
                                          );
                                          _downloadTaadiaPdf(t);
                                        },
                                        cs,
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        onSelected: (v) async {
                                          if (v == 'open') {
                                            await taadiaService.openTaadia(
                                              t.id,
                                            );
                                          } else if (v == 'close') {
                                            await taadiaService.closeTaadia(
                                              t.id,
                                            );
                                          } else if (v == 'edit') {
                                            final titleCtrl =
                                                TextEditingController(
                                                  text: t.title,
                                                );
                                            final descCtrl =
                                                TextEditingController(
                                                  text: t.description,
                                                );
                                            final result = await showDialog<Map<String, String>>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(l.editTitle),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller: titleCtrl,
                                                      textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                                                      decoration:
                                                          InputDecoration(
                                                            labelText: l
                                                                .assessmentTitle,
                                                            hintText:
                                                                t.title,
                                                          ),
                                                      autofocus: true,
                                                    ),
                                                    SizedBox(height: 16),
                                                    TextField(
                                                      controller: descCtrl,
                                                      textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                                                      decoration: InputDecoration(
                                                        labelText: l
                                                            .descriptionOptional,
                                                        hintText: l
                                                            .descriptionHint,
                                                      ),
                                                      maxLines: 3,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: Text(l.cancel),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, {
                                                          'title': titleCtrl
                                                              .text
                                                              .trim(),
                                                          'description':
                                                              descCtrl.text
                                                                  .trim(),
                                                        }),
                                                    child: Text(l.save),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (result != null) {
                                              final updates =
                                                  <String, dynamic>{};
                                              if (result['title']!
                                                      .isNotEmpty &&
                                                  result['title'] !=
                                                      t.title) {
                                                updates['title'] =
                                                    result['title'];
                                              }
                                              if (result['description'] !=
                                                  t.description) {
                                                updates['description'] =
                                                    result['description'];
                                              }
                                              if (updates.isNotEmpty) {
                                                final ok = await taadiaService
                                                    .updateTaadia(
                                                      t.id,
                                                      title:
                                                          updates['title'],
                                                      description:
                                                          updates['description'],
                                                    );
                                                if (mounted && !ok) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l.updateFailed,
                                                      ),
                                                      backgroundColor:
                                                          cs.error,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          } else if (v == 'delete') {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: Text(l.delete),
                                                content: Text(
                                                  l.deleteConfirm(t.title),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: Text(l.cancel),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: Text(
                                                      l.delete,
                                                      style: TextStyle(
                                                        color: cs.error,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true)
                                              await taadiaService
                                                  .deleteTaadia(t.id);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(l.editTitle),
                                          ),
                                          if (t.status == 'active')
                                            PopupMenuItem(
                                              value: 'close',
                                              child: Text(l.close),
                                            )
                                          else
                                            PopupMenuItem(
                                              value: 'open',
                                              child: Text(l.open),
                                            ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              l.delete,
                                              style: TextStyle(
                                                color: cs.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: cs.onSurfaceVariant,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          widget.analytics.logEvent(name: 'create_taadia_clicked');
          final taadiaId = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => CreateTaadiaScreen()),
          );
          if (taadiaId != null && context.mounted) {
            taadiaService.loadTaadias();
            widget.analytics.logEvent(
              name: 'create_taadia_success',
              parameters: {
                'taadia_id': taadiaId,
              },
            );
          }
        },
        child: Icon(Icons.add),
        tooltip: l.createTaadia,
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    ColorScheme cs,
  ) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _downloadTaadiaPdf(Taadia t) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final evalService = Provider.of<EvaluationService>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating PDF...'), backgroundColor: cs.primary),
    );

    final evals = await evalService.getEvaluationsOnce(t.id);

    if (evals.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No evaluations yet for this taadia'),
            backgroundColor: cs.error,
          ),
        );
      }
      return;
    }

    try {
      await PdfService.downloadTaadiaPdf(t, evals, l);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded'),
            backgroundColor: cs.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }
}
