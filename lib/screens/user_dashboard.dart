import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';
import 'package:ta3dia/screens/user_evaluate.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/group_service.dart';

class UserDashboard extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'user_dashboard');
    });
    _loadTaadias();
  }

  Future<void> _loadTaadias() async {
    setState(() => _isLoading = true);
    await Future.wait([
      Provider.of<TaadiaService>(context, listen: false).loadTaadias(),
      Provider.of<GroupService>(context, listen: false).loadGroups(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRtl = l.localeName == 'ar';
    final authService = Provider.of<AuthService>(context);
    final taadiaService = context.watch<TaadiaService>();
    final groupService = context.watch<GroupService>();
    final userId = authService.currentUser?.uid ?? '';
    final userGroupIds = groupService.getUserGroupIds(userId);

    final accessibleTaadias = taadiaService
        .getAccessibleTaadias(userId, userGroupIds)
        .where((t) => t.status == 'active')
        .toList();

    return AppScaffold(
      title: l.appName,
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
                  l.welcomeUser(authService.appUser?.displayName ?? 'User'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l.selectTaadiaToEvaluate,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (context, _) => _SkeletonCard(),
                  )
                : accessibleTaadias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 64, color: cs.outlineVariant),
                            SizedBox(height: 16),
                            Text(
                              l.noActiveTaadias,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: cs.onSurfaceVariant),
                            ),
                            SizedBox(height: 8),
                            Text(
                              l.waitForAdmin,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTaadias,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: accessibleTaadias.length,
                          itemBuilder: (context, index) {
                            final t = accessibleTaadias[index];
                            final classifications = t.classifications ?? [];
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
                                    name: 'user_taadia_clicked',
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
                                  ).then((_) => _loadTaadias());
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: cs.primaryContainer,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Image.asset(
                                              'assets/images/quran image.png',
                                              height: 32,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.assignment_turned_in,
                                                color: cs.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                ),
                                                if (t.description.isNotEmpty) ...[
                                                  SizedBox(height: 4),
                                                  Text(
                                                    t.description,
                                                    style: TextStyle(color: cs.onSurfaceVariant),
                                                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                      if (classifications.isNotEmpty) ...[
                                        SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: classifications.map((cfg) {
                                              return Padding(
                                                padding: EdgeInsets.only(right: 8),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    widget.analytics.logEvent(
                                                      name: 'user_taadia_clicked',
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
                                                    ).then((_) => _loadTaadias());
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                    decoration: BoxDecoration(
                                                      color: cs.secondary,
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: cs.secondary),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.star, size: 14, color: cs.onSecondary),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          cfg.name,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: cs.onSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
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
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest
                        .withValues(alpha: _animation.value),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: _animation.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 220,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: _animation.value * 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
