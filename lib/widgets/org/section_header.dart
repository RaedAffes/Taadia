import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  final Color? color;
  final int? count;

  const SectionHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.cs,
    this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? cs.primary;
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
      ],
    );
  }
}
