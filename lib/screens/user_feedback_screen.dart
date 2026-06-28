import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/feedback_model.dart';
import 'package:ta3dia/services/feedback_service.dart';
import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class UserFeedbackScreen extends StatefulWidget {
  @override
  _UserFeedbackScreenState createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final _newCtrl = TextEditingController();
  final Map<String, TextEditingController> _replyCtrls = {};

  TextEditingController _ctrl(String id) {
    if (!_replyCtrls.containsKey(id)) _replyCtrls[id] = TextEditingController();
    return _replyCtrls[id]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        Provider.of<FeedbackService>(
          context,
          listen: false,
        ).loadMyFeedback(uid);
      }
    });
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    for (var c in _replyCtrls.values) c.dispose();
    super.dispose();
  }

  void _sendNewFeedback(AuthService auth) async {
    final msg = _newCtrl.text.trim();
    if (msg.isEmpty) return;
    final uid = auth.currentUser?.uid ?? '';
    final name = auth.appUser?.displayName ?? '';
    final svc = Provider.of<FeedbackService>(context, listen: false);
    final err = await svc.submitFeedback(uid, name, msg);
    if (mounted) {
      if (err.isEmpty) {
        _newCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.feedbackSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
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

  void _sendReply(
    FeedbackService fb,
    AuthService auth,
    String feedbackId,
  ) async {
    final ctrl = _ctrl(feedbackId);
    final msg = ctrl.text.trim();
    if (msg.isEmpty) return;
    final err = await fb.addReply(
      feedbackId: feedbackId,
      message: msg,
      senderId: auth.currentUser?.uid ?? '',
      senderName: auth.appUser?.displayName ?? '',
      isAdmin: false,
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
    final uid = auth.currentUser?.uid ?? '';

    return AppScaffold(
      title: l.userFeedback,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newCtrl,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l.feedbackHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _sendNewFeedback(auth),
                    icon: Icon(Icons.send, size: 16),
                    label: Text(l.save),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: fb.myLoading
                ? Center(child: CircularProgressIndicator())
                : fb.myItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                        SizedBox(height: 12),
                        Text(
                          l.noFeedbackHistory,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: fb.myItems.length,
                    itemBuilder: (context, index) {
                      final item = fb.myItems[index];
                      final isOwner = item.userId == uid;
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
                                    radius: 14,
                                    backgroundColor: cs.primaryContainer,
                                    child: Icon(
                                      Icons.person,
                                      size: 14,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    l.userFeedback,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    _formatDate(item.createdAt, l),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: cs.error,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () =>
                                          _deleteFeedback(fb, item.id),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                item.message,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  height: 1.4,
                                ),
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
                                            isOwner || r.senderId == uid,
                                            () =>
                                                _deleteReply(fb, item.id, r.id),
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
                                      onTap: () =>
                                          _sendReply(fb, auth, item.id),
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
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, AppLocalizations l) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}
