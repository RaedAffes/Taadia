import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final Color? color;
  final IconData? icon;

  const RoleBadge({
    super.key,
    required this.label,
    required this.cs,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
          ),
        ],
      ),
    );
  }
}
