import 'package:flutter/material.dart';
import 'package:ta3dia/models/organization_model.dart';

class OrgCard extends StatelessWidget {
  final Organization org;
  final ColorScheme cs;
  final Color color;
  final bool isRtl;
  final String membersLabel;
  final String taadiasLabel;
  final String? subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final Widget? trailing;
  final List<Widget>? footerActions;
  final VoidCallback? onTap;

  const OrgCard({
    super.key,
    required this.org,
    required this.cs,
    required this.color,
    required this.isRtl,
    required this.membersLabel,
    required this.taadiasLabel,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.trailing,
    this.footerActions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = org.name.isNotEmpty ? org.name[0].toUpperCase() : '?';
    final status = statusLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (status != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor ?? Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 15, color: cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            membersLabel,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.assessment_outlined, size: 15, color: cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            taadiasLabel,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (footerActions != null && footerActions!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: footerActions!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
