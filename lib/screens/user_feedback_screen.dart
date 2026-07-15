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
  final Map<String, bool> _expanded = {};
  final Map<String, ScrollController> _scrollCtrls = {};
  bool _sending = false;

  TextEditingController _ctrl(String id) {
    if (!_replyCtrls.containsKey(id)) _replyCtrls[id] = TextEditingController();
    return _replyCtrls[id]!;
  }

  ScrollController _scrollCtrl(String id) {
    if (!_scrollCtrls.containsKey(id)) _scrollCtrls[id] = ScrollController();
    return _scrollCtrls[id]!;
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
    for (var c in _scrollCtrls.values) c.dispose();
    super.dispose();
  }

  void _sendNewFeedback(AuthService auth) async {
    final msg = _newCtrl.text.trim();
    if (msg.isEmpty || _sending) return;
    setState(() => _sending = true);
    final uid = auth.currentUser?.uid ?? '';
    final name = auth.appUser?.displayName ?? '';
    final svc = Provider.of<FeedbackService>(context, listen: false);
    final err = await svc.submitFeedback(uid, name, msg);
    if (mounted) {
      setState(() => _sending = false);
      if (err.isEmpty) {
        _newCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteFeedback(FeedbackService fb, String id) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error, size: 22),
            SizedBox(width: 8),
            Text(l.areYouSure, style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(l.confirmDeleteFeedback, style: TextStyle(height: 1.5)),
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
    if (ok != true) return;
    final err = await fb.deleteFeedback(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isEmpty ? l.feedbackDeleted : err),
          backgroundColor: err.isEmpty ? null : cs.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error, size: 22),
            SizedBox(width: 8),
            Text(l.areYouSure, style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(l.confirmDeleteReply, style: TextStyle(height: 1.5)),
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
    if (ok != true) return;
    final err = await fb.deleteReply(feedbackId, replyId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isEmpty ? l.replyDeleted : err),
          backgroundColor: err.isEmpty ? null : cs.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildChatBubble({
    required String message,
    required bool isAdmin,
    required String senderName,
    required DateTime time,
    required bool canDelete,
    required VoidCallback? onDelete,
    required ColorScheme cs,
    required AppLocalizations l,
    required bool isRtl,
  }) {
    final isMe = !isAdmin;
    final bubbleColor = isAdmin
        ? cs.tertiaryContainer.withValues(alpha: 0.5)
        : cs.primaryContainer.withValues(alpha: 0.5);
    final textColor = isAdmin ? cs.onTertiaryContainer : cs.onPrimaryContainer;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return GestureDetector(
      onLongPress: canDelete ? onDelete : null,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 2,
          left: isMe ? 48 : 8,
          right: isMe ? 8 : 48,
        ),
        child: Column(
          crossAxisAlignment: align,
          children: [
            if (isAdmin)
              Padding(
                padding: EdgeInsets.only(bottom: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 12, color: cs.tertiary),
                    SizedBox(width: 4),
                    Text(
                      senderName.isNotEmpty ? senderName : l.admin,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.admin,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _relativeTime(time),
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      if (canDelete) ...[
                        SizedBox(width: 6),
                        Icon(
                          Icons.delete_outline,
                          size: 11,
                          color: cs.error.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationThread(FeedbackItem item, FeedbackService fb, AuthService auth, AppLocalizations l, ColorScheme cs) {
    final isExpanded = _expanded[item.id] ?? false;
    final uid = auth.currentUser?.uid ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expanded[item.id] = !isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.person, color: cs.onPrimary, size: 20),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.userFeedback,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          item.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _relativeTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      StreamBuilder<List<FeedbackReply>>(
                        stream: fb.repliesStream(item.id),
                        builder: (context, snap) {
                          final count = snap.data?.length ?? 0;
                          if (count == 0) return SizedBox.shrink();
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _deleteFeedback(fb, item.id),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 16, color: cs.error.withValues(alpha: 0.7)),
                    ),
                  ),
                  SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Container(
              padding: EdgeInsets.only(left: 14, right: 14, top: 4),
              child: StreamBuilder<List<FeedbackReply>>(
                stream: fb.repliesStream(item.id),
                builder: (context, snap) {
                  final replies = snap.data ?? [];
                  return Column(
                    children: [
                      if (replies.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${replies.length} ${replies.length == 1 ? l.reply : l.reply}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                      ...replies.map(
                        (r) => _buildChatBubble(
                          message: r.message,
                          isAdmin: r.isAdmin,
                          senderName: r.senderName,
                          time: r.createdAt,
                          canDelete: r.senderId == uid,
                          onDelete: () => _deleteReply(fb, item.id, r.id),
                          cs: cs,
                          l: l,
                          isRtl: Directionality.of(context) == TextDirection.rtl,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8, bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ctrl(item.id),
                                decoration: InputDecoration(
                                  hintText: l.replyHint,
                                  hintStyle: TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: cs.outlineVariant),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: cs.outlineVariant),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: cs.surface,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: 2,
                                minLines: 1,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendReply(fb, auth, item.id),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send_rounded, size: 18, color: cs.onPrimary),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                onPressed: () => _sendReply(fb, auth, item.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 250),
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
      title: l.userFeedback,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4), width: 1),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _newCtrl,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l.feedbackHint,
                        hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Icon(Icons.send_rounded, size: 18, color: cs.onPrimary),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: _sending ? null : () => _sendNewFeedback(auth),
                    ),
                  ),
                  SizedBox(width: 6),
                ],
              ),
            ),
          ),
          Expanded(
            child: fb.myLoading
                ? Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  )
                : fb.myItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: cs.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              l.noFeedbackHistory,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              l.feedbackHint,
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: fb.myItems.length,
                        itemBuilder: (context, index) {
                          final item = fb.myItems[index];
                          return _buildConversationThread(item, fb, auth, l, cs);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
