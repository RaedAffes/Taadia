import 'dart:math' as math;
import 'package:flutter/material.dart';

class IslamicHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final double height;
  final Widget? leading;
  final List<Widget>? actions;

  const IslamicHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 200,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  cs.surface,
                  cs.primary.withValues(alpha: 0.3),
                  cs.primary,
                ]
              : [
                  cs.primary,
                  Color(0xFF6B5D4F),
                  Color(0xFF4A3F35),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GeometricPatternPainter(
              color: isDark
                  ? cs.onPrimary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.1),
              secondaryColor: isDark
                  ? cs.onPrimary.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            top: -height * 0.5,
            right: -height * 0.2,
            child: Container(
              width: height * 1.1,
              height: height * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -height * 0.3,
            left: -height * 0.2,
            child: Container(
              width: height * 0.7,
              height: height * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? cs.secondary.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 0,
            right: 0,
            child: IconTheme(
              data: IconThemeData(color: Colors.white),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  Spacer(),
                  if (actions != null) ...[
                    ...actions!,
                    SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: (leading != null || actions != null) ? 52 : 24,
                bottom: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  _GeometricPatternPainter({required this.color, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final secondaryPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDim = math.max(size.width, size.height);
    final spacing = maxDim * 0.13;
    final r = spacing * 0.4;

    for (double row = -1; row <= 2; row++) {
      for (double col = -1; col <= 2; col++) {
        final ox = cx + (col - 0.5) * spacing;
        final oy = cy + (row - 0.5) * spacing;

        // 12-pointed star rosette
        final starPath = Path();
        for (int i = 0; i < 12; i++) {
          final a = (math.pi / 6) * i - math.pi / 2;
          final outer = Offset(
            ox + r * math.cos(a),
            oy + r * math.sin(a),
          );
          final innerAngle = a + math.pi / 12;
          final inner = Offset(
            ox + r * 0.45 * math.cos(innerAngle),
            oy + r * 0.45 * math.sin(innerAngle),
          );
          if (i == 0) {
            starPath.moveTo(outer.dx, outer.dy);
          } else {
            starPath.lineTo(outer.dx, outer.dy);
          }
          starPath.lineTo(inner.dx, inner.dy);
        }
        starPath.close();
        canvas.drawPath(starPath, paint);

        // inner 12-petal rosette
        final petalPath = Path();
        for (int i = 0; i < 12; i++) {
          final a = (math.pi / 6) * i - math.pi / 2 + math.pi / 12;
          final p1 = Offset(
            ox + r * 0.5 * math.cos(a - math.pi / 12),
            oy + r * 0.5 * math.sin(a - math.pi / 12),
          );
          final p2 = Offset(
            ox + r * 0.55 * math.cos(a),
            oy + r * 0.55 * math.sin(a),
          );
          final p3 = Offset(
            ox + r * 0.5 * math.cos(a + math.pi / 12),
            oy + r * 0.5 * math.sin(a + math.pi / 12),
          );
          if (i == 0) {
            petalPath.moveTo(p1.dx, p1.dy);
          }
          petalPath.quadraticBezierTo(p2.dx, p2.dy, p3.dx, p3.dy);
        }
        petalPath.close();
        canvas.drawPath(petalPath, secondaryPaint);

        // central dot
        canvas.drawCircle(Offset(ox, oy), r * 0.08, fillPaint);

        // hexagon connecting adjacent stars
        if (col < 1.5) {
          final nx = cx + (col - 0.5 + 1) * spacing;
          for (int i = 0; i < 6; i++) {
            final a = (math.pi / 3) * i - math.pi / 6;
            final from = Offset(
              ox + r * 0.65 * math.cos(a),
              oy + r * 0.65 * math.sin(a),
            );
            final to = Offset(
              nx + r * 0.65 * math.cos(math.pi - a),
              oy + r * 0.65 * math.sin(math.pi - a),
            );
            canvas.drawLine(from, to, secondaryPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
