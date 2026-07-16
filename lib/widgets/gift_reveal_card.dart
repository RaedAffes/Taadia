import 'dart:math' as math;
import 'package:flutter/material.dart';

class GiftRevealCard extends StatefulWidget {
  final Widget child;
  final bool showGift;
  final VoidCallback? onRevealed;

  const GiftRevealCard({
    super.key,
    required this.child,
    this.showGift = false,
    this.onRevealed,
  });

  @override
  State<GiftRevealCard> createState() => _GiftRevealCardState();
}

class _GiftRevealCardState extends State<GiftRevealCard>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _confettiController;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    if (widget.showGift && !_revealed) {
      _startReveal();
    }
  }

  @override
  void didUpdateWidget(GiftRevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGift && !oldWidget.showGift && !_revealed) {
      _startReveal();
    }
    if (!widget.showGift) {
      _revealed = false;
    }
  }

  Future<void> _startReveal() async {
    _confettiController.forward();
    await _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _revealed = true);
      widget.onRevealed?.call();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showGift || _revealed) return widget.child;

    final t = _mainController.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GiftPainter(
                openProgress: t,
                confettiProgress: _confettiController.value,
              ),
            ),
          ),
        ),
        if (t > 0.55)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: ((t - 0.55) / 0.45).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + ((t - 0.55) / 0.45).clamp(0.0, 1.0) * 0.1,
                  child: widget.child,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GiftPainter extends CustomPainter {
  final double openProgress;
  final double confettiProgress;

  static const Color _red = Color(0xFFC62828);
  static const Color _redLight = Color(0xFFEF5350);
  static const Color _redDark = Color(0xFF8E0000);
  static const Color _white = Colors.white;

  _GiftPainter({required this.openProgress, required this.confettiProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = openProgress;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final bgOpacity = t < 0.92 ? 1.0 : (1.0 - (t - 0.92) / 0.08).clamp(0.0, 1.0);
    if (bgOpacity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = _red.withOpacity(bgOpacity),
      );
    }

    _drawConfetti(canvas, size, cx, cy, confettiProgress);

    if (t >= 0.92) return;

    final appear = Curves.easeOutBack.transform((t * 5).clamp(0.0, 1.0));
    final fadeOut = ((t - 0.6) / 0.32).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(appear);
    canvas.translate(-cx, -cy);

    _drawShadow(canvas, w, h, fadeOut);

    final radius = 16.0;
    _drawBoxBody(canvas, 0, 0, w, h, radius, fadeOut);
    _drawVerticalRibbon(canvas, 0, 0, w, h, radius, fadeOut);
    _drawHorizontalRibbon(canvas, 0, 0, w, h, fadeOut);
    _drawBow(canvas, cx, cy - h * 0.08, w, fadeOut);

    _drawGlow(canvas, w, h, cx, cy, t);
    _drawSparkles(canvas, cx, cy, w, h, t);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 5, w, h),
        const Radius.circular(16),
      ),
      shadowPaint,
    );
  }

  void _drawBoxBody(Canvas canvas, double left, double top, double w, double h, double radius, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      Radius.circular(radius),
    );

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _redLight.withOpacity(opacity),
          _red.withOpacity(opacity),
          _redDark.withOpacity(opacity * 0.8),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(left, top, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bodyPaint);

    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _white.withOpacity(0.1 * opacity),
          _white.withOpacity(0.02 * opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawRRect(rrect, gloss);

    final borderPaint = Paint()
      ..color = _redDark.withOpacity(opacity * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawVerticalRibbon(Canvas canvas, double left, double top, double w, double h, double radius, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final rw = math.max(w * 0.09, 14.0);
    final ribbonLeft = left + w / 2 - rw / 2;

    final ribbonPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(ribbonLeft, top, rw, h),
        Radius.circular(rw * 0.25),
      ));

    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _white.withOpacity(0.7 * opacity),
          _white.withOpacity(0.95 * opacity),
          _white.withOpacity(0.7 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(ribbonLeft, top, rw, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  void _drawHorizontalRibbon(Canvas canvas, double left, double top, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final rh = math.max(h * 0.08, 12.0);
    final ribbonTop = top + h * 0.42 - rh / 2;

    final ribbonPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, ribbonTop, w, rh),
        Radius.circular(rh * 0.25),
      ));

    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _white.withOpacity(0.7 * opacity),
          _white.withOpacity(0.95 * opacity),
          _white.withOpacity(0.7 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, ribbonTop, w, rh))
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  void _drawBow(Canvas canvas, double cx, double cy, double w, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final bowPaint = Paint()
      ..color = _white.withOpacity(0.95 * opacity)
      ..style = PaintingStyle.fill;

    final bowShadow = Paint()
      ..color = Colors.black.withOpacity(0.08 * opacity)
      ..style = PaintingStyle.fill;

    final loopW = w * 0.18;
    final loopH = w * 0.14;

    final leftLoop = Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx - loopW * 0.3, cy - loopH * 1.2,
        cx - loopW * 1.1, cy - loopH * 1.1,
        cx - loopW * 0.8, cy - loopH * 0.1,
      )
      ..cubicTo(
        cx - loopW * 0.6, cy + loopH * 0.15,
        cx - loopW * 0.1, cy + loopH * 0.1,
        cx, cy,
      );

    final rightLoop = Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx + loopW * 0.3, cy - loopH * 1.2,
        cx + loopW * 1.1, cy - loopH * 1.1,
        cx + loopW * 0.8, cy - loopH * 0.1,
      )
      ..cubicTo(
        cx + loopW * 0.6, cy + loopH * 0.15,
        cx + loopW * 0.1, cy + loopH * 0.1,
        cx, cy,
      );

    canvas.drawPath(leftLoop.shift(const Offset(0, 2)), bowShadow);
    canvas.drawPath(rightLoop.shift(const Offset(0, 2)), bowShadow);

    canvas.drawPath(leftLoop, bowPaint);
    canvas.drawPath(rightLoop, bowPaint);

    final knotPaint = Paint()
      ..color = _white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: loopW * 0.45, height: loopH * 0.5),
      knotPaint,
    );

    final ribbonTailPaint = Paint()
      ..color = _white.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final leftTail = Path()
      ..moveTo(cx - loopW * 0.15, cy + loopH * 0.1)
      ..cubicTo(
        cx - loopW * 0.4, cy + loopH * 0.8,
        cx - loopW * 0.7, cy + loopH * 1.3,
        cx - loopW * 0.5, cy + loopH * 1.6,
      );
    canvas.drawPath(leftTail, ribbonTailPaint);

    final rightTail = Path()
      ..moveTo(cx + loopW * 0.15, cy + loopH * 0.1)
      ..cubicTo(
        cx + loopW * 0.4, cy + loopH * 0.8,
        cx + loopW * 0.7, cy + loopH * 1.3,
        cx + loopW * 0.5, cy + loopH * 1.6,
      );
    canvas.drawPath(rightTail, ribbonTailPaint);
  }

  void _drawGlow(Canvas canvas, double w, double h, double cx, double cy, double t) {
    if (t < 0.2 || t > 0.85) return;
    final glowT = ((t - 0.2) / 0.65).clamp(0.0, 1.0);
    final glowOpacity = (glowT < 0.5 ? glowT * 2 : (1.0 - glowT) * 2).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _white.withOpacity(0.12 * glowOpacity),
          _white.withOpacity(0.04 * glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: math.max(w, h) * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
  }

  void _drawConfetti(Canvas canvas, Size size, double cx, double cy, double ct) {
    if (ct <= 0) return;
    final rng = math.Random(7);
    final colors = [
      _white,
      _redLight,
      Color(0xFFFFCDD2),
      Color(0xFFFFEBEE),
      Color(0xFFFFAB91),
      Color(0xFFFFC107),
    ];
    final confettiPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 45; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 80.0 + rng.nextDouble() * 180.0;
      final gravBend = (rng.nextDouble() - 0.5) * 70.0;
      final rotSpeed = (rng.nextDouble() - 0.5) * 12.0;
      final x = cx + math.cos(angle) * speed * ct + gravBend * ct * ct;
      final y = cy + math.sin(angle) * speed * ct - 60 * ct + 220 * ct * ct;
      final rot = ct * rotSpeed;
      final cw = 3.0 + rng.nextDouble() * 5.0;
      final ch = 2.0 + rng.nextDouble() * 3.0;
      final confettiOpacity = (1.0 - ct * 0.5).clamp(0.0, 1.0);
      confettiPaint.color = colors[i % colors.length].withOpacity(confettiOpacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: cw, height: ch),
          const Radius.circular(1),
        ),
        confettiPaint,
      );
      canvas.restore();
    }
  }

  void _drawSparkles(Canvas canvas, double cx, double cy, double boxW, double boxH, double t) {
    if (t < 0.15 || t > 0.8) return;
    final sparkT = ((t - 0.15) / 0.65).clamp(0.0, 1.0);
    final sparkleOpacity = (sparkT < 0.5 ? sparkT * 2 : (1.0 - sparkT) * 2).clamp(0.0, 1.0);
    final rng = math.Random(99);
    final sparklePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * math.pi * 2 + t * math.pi * 0.8;
      final dist = (boxW * 0.3 + rng.nextDouble() * boxW * 0.4) * sparkT;
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist * 0.7;
      final sr = (1.5 + rng.nextDouble() * 2.0) * sparkleOpacity;
      final sparkleColors = [_white, Color(0xFFFFF176), Color(0xFFFFD700)];
      sparklePaint.color = sparkleColors[i % sparkleColors.length].withOpacity(sparkleOpacity * 0.85);
      _drawStar(canvas, sx, sy, sr, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 - math.pi / 2;
      final outerX = cx + math.cos(angle) * r;
      final outerY = cy + math.sin(angle) * r;
      final innerAngle = angle + math.pi / 5;
      final innerX = cx + math.cos(innerAngle) * r * 0.35;
      final innerY = cy + math.sin(innerAngle) * r * 0.35;
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GiftPainter old) =>
      old.openProgress != openProgress || old.confettiProgress != confettiProgress;
}
