import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/feedback_model.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/feedback_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class AdminFeedbackScreen extends StatefulWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _AdminFeedbackScreenState createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final Map<String, TextEditingController> _replyCtrls = {};

  TextEditingController _ctrl(String id) {
    if (!_replyCtrls.containsKey(id)) _replyCtrls[id] = TextEditingController();
    return _replyCtrls[id]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.analytics.logScreenView(screenName: 'admin_feedback_screen');
      Provider.of<FeedbackService>(context, listen: false).loadFeedback();
    });
  }

  @override
  void dispose() {
    for (var c in _replyCtrls.values) c.dispose();
    super.dispose();
  }

  void _sendReply(FeedbackService fb, AuthService auth, String id) async {
    final ctrl = _ctrl(id);
    final msg = ctrl.text.trim();
    if (msg.isEmpty) return;
    widget.analytics.logEvent(
      name: 'admin_send_reply',
      parameters: {
        'feedback_id': id,
        'message': msg,
      },
    );
    final err = await fb.addReply(
      feedbackId: id,
      message: msg,
      senderId: auth.currentUser?.uid ?? '',
      senderName: auth.appUser?.displayName ?? '',
      isAdmin: true,
    );
    if (mounted) {
      ctrl.clear();
      if (err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteFeedback(FeedbackService fb, String id) async {
    final l = AppLocalizations.of(context)!;
    widget.analytics.logEvent(
      name: 'admin_delete_feedback',
      parameters: {
        'feedback_id': id,
      },
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.areYouSure),
        content: Text(l.confirmDeleteFeedback),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await fb.deleteFeedback(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isEmpty ? l.feedbackDeleted : err),
          backgroundColor: err.isEmpty
              ? null
              : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteReply(
    FeedbackService fb,
    String feedbackId,
    String replyId,
  ) async {
    final l = AppLocalizations.of(context)!;
    widget.analytics.logEvent(
      name: 'admin_delete_reply',
      parameters: {
        'feedback_id': feedbackId,
        'reply_id': replyId,
      },
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.areYouSure),
        content: Text(l.confirmDeleteReply),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await fb.deleteReply(feedbackId, replyId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isEmpty ? l.replyDeleted : err),
          backgroundColor: err.isEmpty
              ? null
              : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _replyBubble(
    FeedbackReply r,
    bool canDelete,
    VoidCallback onDelete,
    AppLocalizations l,
    ColorScheme cs,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (r.isAdmin ? cs.tertiaryContainer : cs.primaryContainer)
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            r.isAdmin ? Icons.shield : Icons.person,
            size: 14,
            color: r.isAdmin ? cs.tertiary : cs.primary,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.isAdmin ? cs.tertiary : cs.primary,
                      ),
                    ),
                    if (r.isAdmin) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                          child: Text(
                          l.admin,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cs.tertiary,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 6),
                    Text(
                      _formatDate(r.createdAt, l),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  r.message,
                  style: TextStyle(
                    color: r.isAdmin
                        ? cs.onTertiaryContainer
                        : cs.onPrimaryContainer,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 16),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              color: cs.error,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fb = Provider.of<FeedbackService>(context);
    final auth = Provider.of<AuthService>(context);
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l.viewFeedback,
      body: fb.loading
          ? Center(child: CircularProgressIndicator())
          : fb.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l.noFeedback,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: fb.items.length,
              itemBuilder: (context, index) {
                final item = fb.items[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                item.userName.isNotEmpty
                                    ? item.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(item.createdAt, l),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: cs.error,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _deleteFeedback(fb, item.id),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          item.message,
                          style: TextStyle(color: cs.onSurface, height: 1.4),
                        ),
                        StreamBuilder<List<FeedbackReply>>(
                          stream: fb.repliesStream(item.id),
                          builder: (context, snap) {
                            final replies = snap.data ?? [];
                            if (replies.isEmpty) return SizedBox.shrink();
                            return Column(
                              children: replies
                                  .map(
                                    (r) => _replyBubble(
                                      r,
                                      true,
                                      () => _deleteReply(fb, item.id, r.id),
                                      l,
                                      cs,
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ctrl(item.id),
                                decoration: InputDecoration(
                                  hintText: l.replyHint,
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                maxLines: 2,
                                minLines: 1,
                              ),
                            ),
                            SizedBox(width: 8),
                            Material(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _sendReply(fb, auth, item.id),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.send,
                                    size: 18,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt, AppLocalizations l) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}
