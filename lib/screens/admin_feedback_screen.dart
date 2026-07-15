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
  final Map<String, bool> _expanded = {};
  bool _searching = false;
  final _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _sendReply(FeedbackService fb, AuthService auth, String id) async {
    final ctrl = _ctrl(id);
    final msg = ctrl.text.trim();
    if (msg.isEmpty) return;
    widget.analytics.logEvent(
      name: 'admin_send_reply',
      parameters: {'feedback_id': id, 'message': msg},
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteFeedback(FeedbackService fb, String id) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    widget.analytics.logEvent(
      name: 'admin_delete_feedback',
      parameters: {'feedback_id': id},
    );
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
    widget.analytics.logEvent(
      name: 'admin_delete_reply',
      parameters: {'feedback_id': feedbackId, 'reply_id': replyId},
    );
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
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
  }) {
    final isMe = isAdmin;
    final bubbleColor = isAdmin
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : cs.tertiaryContainer.withValues(alpha: 0.5);
    final textColor = isAdmin ? cs.onPrimaryContainer : cs.onTertiaryContainer;
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
            if (!isAdmin)
              Padding(
                padding: EdgeInsets.only(bottom: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 12, color: cs.tertiary),
                    SizedBox(width: 4),
                    Text(
                      senderName.isNotEmpty ? senderName : 'User',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            if (isAdmin)
              Padding(
                padding: EdgeInsets.only(bottom: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 12, color: cs.primary),
                    SizedBox(width: 4),
                    Text(
                      senderName.isNotEmpty ? senderName : l.admin,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.admin,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
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

  Color _avatarColor(String name, ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.tertiary,
      Color(0xFF7B8C6B),
      Color(0xFF6B7B8C),
      Color(0xFF8C6B7B),
      Color(0xFF8B7D6B),
    ];
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fb = Provider.of<FeedbackService>(context);
    final auth = Provider.of<AuthService>(context);
    final cs = Theme.of(context).colorScheme;

    final filteredItems = _searching && _searchCtrl.text.isNotEmpty
        ? fb.items
            .where(
              (i) => i.userName
                  .toLowerCase()
                  .contains(_searchCtrl.text.toLowerCase()),
            )
            .toList()
        : fb.items;

    return AppScaffold(
      title: l.viewFeedback,
      actions: [
        IconButton(
          icon: Icon(_searching ? Icons.close : Icons.search, size: 22),
          onPressed: () {
            setState(() {
              _searching = !_searching;
              if (!_searching) _searchCtrl.clear();
            });
          },
        ),
      ],
      body: Column(
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _searching
                ? Container(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l.admin == 'Admin' ? 'Search users...' : 'بحث عن مستخدم...',
                        hintStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                : SizedBox.shrink(),
          ),
          Expanded(
            child: fb.loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : filteredItems.isEmpty
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
                                Icons.inbox_outlined,
                                size: 40,
                                color: cs.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              l.noFeedback,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isExpanded = _expanded[item.id] ?? false;
                          final initials = item.userName.isNotEmpty
                              ? item.userName[0].toUpperCase()
                              : '?';

                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _expanded[item.id] = !isExpanded;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _avatarColor(item.userName, cs),
                                              _avatarColor(item.userName, cs)
                                                  .withValues(alpha: 0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.userName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: cs.onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _relativeTime(
                                                      item.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 3),
                                            Text(
                                              item.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                                height: 1.3,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            StreamBuilder<List<FeedbackReply>>(
                                              stream:
                                                  fb.repliesStream(item.id),
                                              builder: (context, snap) {
                                                final replies =
                                                    snap.data ?? [];
                                                if (replies.isEmpty)
                                                  return SizedBox.shrink();
                                                final lastReply =
                                                    replies.last;
                                                return Row(
                                                  children: [
                                                    Icon(
                                                      lastReply.isAdmin
                                                          ? Icons.shield
                                                          : Icons.person,
                                                      size: 12,
                                                      color: lastReply.isAdmin
                                                          ? cs.primary
                                                          : cs.tertiary,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '${lastReply.senderName}: ${lastReply.message}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: cs
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: cs.primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        '${replies.length}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: cs.onPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: cs.error
                                                  .withValues(alpha: 0.6),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            onPressed: () =>
                                                _deleteFeedback(fb, item.id),
                                          ),
                                          SizedBox(height: 4),
                                          AnimatedRotation(
                                            turns: isExpanded ? 0.5 : 0,
                                            duration:
                                                Duration(milliseconds: 200),
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 18,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: SizedBox.shrink(),
                                secondChild: Container(
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      StreamBuilder<List<FeedbackReply>>(
                                        stream: fb.repliesStream(item.id),
                                        builder: (context, snap) {
                                          final replies =
                                              snap.data ?? [];
                                          return Column(
                                            children: [
                                              if (replies.isNotEmpty)
                                                Container(
                                                  margin:
                                                      EdgeInsets.only(
                                                          bottom: 8),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                          child: Divider(
                                                              color: cs
                                                                  .outlineVariant
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5))),
                                                      Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal:
                                                                    12),
                                                        child: Text(
                                                          '${replies.length} ${l.reply}',
                                                          style:
                                                              TextStyle(
                                                            fontSize: 10,
                                                            color: cs
                                                                .onSurfaceVariant,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                          child: Divider(
                                                              color: cs
                                                                  .outlineVariant
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5))),
                                                    ],
                                                  ),
                                                ),
                                              ...replies.map(
                                                (r) => _buildChatBubble(
                                                  message: r.message,
                                                  isAdmin: r.isAdmin,
                                                  senderName:
                                                      r.senderName,
                                                  time: r.createdAt,
                                                  canDelete: true,
                                                  onDelete: () =>
                                                      _deleteReply(
                                                          fb,
                                                          item.id,
                                                          r.id),
                                                  cs: cs,
                                                  l: l,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 8, bottom: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _ctrl(item.id),
                                                decoration:
                                                    InputDecoration(
                                                  hintText: l.replyHint,
                                                  hintStyle: TextStyle(
                                                      fontSize: 13),
                                                  border:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                24),
                                                    borderSide:
                                                        BorderSide(
                                                            color: cs
                                                                .outlineVariant),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                24),
                                                    borderSide:
                                                        BorderSide(
                                                            color: cs
                                                                .outlineVariant),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                24),
                                                    borderSide:
                                                        BorderSide(
                                                            color: cs
                                                                .primary,
                                                            width:
                                                                1.5),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      cs.surface,
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets
                                                          .symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                maxLines: 2,
                                                minLines: 1,
                                                textInputAction:
                                                    TextInputAction
                                                        .send,
                                                onSubmitted: (_) =>
                                                    _sendReply(
                                                        fb, auth, item.id),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient:
                                                    LinearGradient(
                                                  colors: [
                                                    cs.primary,
                                                    cs.primary
                                                        .withValues(
                                                            alpha: 0.8),
                                                  ],
                                                ),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons
                                                      .send_rounded,
                                                  size: 18,
                                                  color:
                                                      cs.onPrimary,
                                                ),
                                                padding:
                                                    EdgeInsets.zero,
                                                constraints:
                                                    BoxConstraints(
                                                  minWidth: 40,
                                                  minHeight: 40,
                                                ),
                                                onPressed: () =>
                                                    _sendReply(
                                                        fb,
                                                        auth,
                                                        item.id),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: Duration(milliseconds: 250),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
