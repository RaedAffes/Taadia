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
  Size? _cardSize;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        _cardSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Opacity(
              opacity: 0,
              child: widget.child,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LuxuryGiftPainter(
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
      },
    );
  }
}

class _LuxuryGiftPainter extends CustomPainter {
  final double openProgress;
  final double confettiProgress;

  _LuxuryGiftPainter({
    required this.openProgress,
    required this.confettiProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = openProgress;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    _drawConfetti(canvas, size, cx, cy, confettiProgress);

    if (t >= 0.95) return;

    final appear = Curves.easeOutBack.transform((t * 5).clamp(0.0, 1.0));
    final lidOpen = ((t - 0.3) / 0.35).clamp(0.0, 1.0);
    final lidCurve = Curves.easeOutBack.transform(lidOpen);
    final fadeOut = ((t - 0.6) / 0.35).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(appear);
    canvas.translate(-cx, -cy);

    _drawShadow(canvas, w, h, fadeOut);

    final radius = 12.0;
    final lidH = h * 0.22;
    final bodyTop = lidH;
    final bodyH = h - lidH;

    _drawBoxBody(canvas, 0, bodyTop, w, bodyH, radius, fadeOut);

    _drawVerticalRibbon(canvas, 0, bodyTop, w, bodyH, fadeOut);
    _drawHorizontalRibbon(canvas, 0, bodyTop, w, bodyH, fadeOut);

    _drawWhitePattern(canvas, 0, bodyTop, w, bodyH, fadeOut);

    if (fadeOut < 1.0) {
      _drawLid(canvas, 0, 0, w, lidH, radius, lidCurve, fadeOut);
      _drawLidRibbon(canvas, 0, 0, w, lidH, lidCurve, fadeOut);
      _drawBow(canvas, cx, lidH * 0.75, lidCurve, fadeOut, w);
    }

    _drawGlow(canvas, w, h, cx, cy, t);

    _drawSparkles(canvas, cx, cy, w, h, t);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 6, w, h),
        const Radius.circular(12),
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
      ..color = Color(0xFFB71C1C).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bodyPaint);

    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15 * opacity),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1 * opacity),
        ],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawRRect(rrect, glossPaint);

    final innerGloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD32F2F).withValues(alpha: opacity),
          Color(0xFFB71C1C).withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawRRect(rrect, innerGloss);

    final borderPaint = Paint()
      ..color = Color(0xFF8E0000).withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawVerticalRibbon(Canvas canvas, double left, double top, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final rw = math.max(w * 0.08, 14.0);
    final ribbonLeft = left + w / 2 - rw / 2;

    final ribbonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(ribbonLeft, top, rw, h),
      ribbonPaint,
    );

    final stripePaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.7 * opacity)
      ..style = PaintingStyle.fill;
    final stripeW = rw * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(ribbonLeft + rw / 2 - stripeW / 2, top, stripeW, h),
      stripePaint,
    );
  }

  void _drawHorizontalRibbon(Canvas canvas, double left, double top, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final rh = math.max(h * 0.08, 14.0);
    final ribbonTop = top + h * 0.42 - rh / 2;

    final ribbonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(left, ribbonTop, w, rh),
      ribbonPaint,
    );

    final stripePaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.7 * opacity)
      ..style = PaintingStyle.fill;
    final stripeH = rh * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(left, ribbonTop + rh / 2 - stripeH / 2, w, stripeH),
      stripePaint,
    );
  }

  void _drawWhitePattern(Canvas canvas, double left, double top, double w, double h, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final patternPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final spacing = 20.0;
    for (double x = left; x < left + w; x += spacing) {
      for (double y = top; y < top + h; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, patternPaint);
      }
    }
  }

  void _drawLid(Canvas canvas, double left, double top, double w, double hLid, double radius, double lidCurve, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final liftY = -lidCurve * hLid * 2.2;
    final tiltAngle = lidCurve * 0.3;

    canvas.save();
    canvas.translate(left + w * 0.5, top + hLid);
    canvas.rotate(-tiltAngle);
    canvas.translate(-w * 0.5, -hLid);

    final lidRect = Rect.fromLTWH(-3, liftY, w + 6, hLid + 4);
    final lidRRect = RRect.fromRectAndRadius(lidRect, Radius.circular(radius));

    final lidBasePaint = Paint()
      ..color = Color(0xFFD32F2F).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lidRRect, lidBasePaint);

    final lidGradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE53935).withValues(alpha: opacity),
          Color(0xFFC62828).withValues(alpha: opacity),
        ],
      ).createShader(lidRect);
    canvas.drawRRect(lidRRect, lidGradPaint);

    final lidHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25 * opacity),
          Colors.white.withValues(alpha: 0.05 * opacity),
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 1.0],
      ).createShader(lidRect);
    canvas.drawRRect(lidRRect, lidHighlight);

    final lidEdgePaint = Paint()
      ..color = Color(0xFF8E0000).withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(lidRRect, lidEdgePaint);

    final bottomEdgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bottomY = liftY + hLid + 2;
    canvas.drawLine(
      Offset(left + 4 > -3 ? 4 : -3, bottomY),
      Offset(w - 4 < w + 3 ? w - 4 : w + 3, bottomY),
      bottomEdgePaint,
    );

    canvas.restore();
  }

  void _drawLidRibbon(Canvas canvas, double left, double top, double w, double hLid, double lidCurve, double fadeOut) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final liftY = -lidCurve * hLid * 2.2;
    final tiltAngle = lidCurve * 0.3;
    final rw = math.max(w * 0.08, 14.0);

    canvas.save();
    canvas.translate(left + w * 0.5, top + hLid);
    canvas.rotate(-tiltAngle);
    canvas.translate(-w * 0.5, -hLid);

    final ribbonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - rw / 2, liftY, rw, hLid + 4),
      ribbonPaint,
    );

    final rh = math.max(hLid * 0.3, 6.0);
    canvas.drawRect(
      Rect.fromLTWH(-3, liftY + hLid * 0.45, w + 6, rh),
      ribbonPaint,
    );

    final goldPaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.7 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - rw * 0.1, liftY, rw * 0.2, hLid + 4),
      goldPaint,
    );

    canvas.restore();
  }

  void _drawBow(Canvas canvas, double cx, double cy, double lidCurve, double fadeOut, double w) {
    final opacity = (1.0 - fadeOut).clamp(0.0, 1.0);
    final liftY = -lidCurve * 2.2;
    final bowCy = cy + liftY * 18;
    final s = math.max(w * 0.06, 12.0);

    final bowShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final bowMain = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final bowGold = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final leftLoop = Path()
      ..moveTo(cx, bowCy + 3)
      ..cubicTo(cx - s * 1.5, bowCy - s * 0.5, cx - s * 2.5, bowCy - s * 3, cx - s * 1.0, bowCy - s * 2.0)
      ..cubicTo(cx - s * 0.3, bowCy - s * 1.2, cx, bowCy - s * 0.3, cx, bowCy + 3);
    canvas.drawPath(leftLoop.shift(const Offset(1, 2)), bowShadow);
    canvas.drawPath(leftLoop, bowMain);

    final rightLoop = Path()
      ..moveTo(cx, bowCy + 3)
      ..cubicTo(cx + s * 1.5, bowCy - s * 0.5, cx + s * 2.5, bowCy - s * 3, cx + s * 1.0, bowCy - s * 2.0)
      ..cubicTo(cx + s * 0.3, bowCy - s * 1.2, cx, bowCy - s * 0.3, cx, bowCy + 3);
    canvas.drawPath(rightLoop.shift(const Offset(1, 2)), bowShadow);
    canvas.drawPath(rightLoop, bowMain);

    final centerHighlight = Paint()
      ..color = Color(0xFFFFF9C4).withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bowCy), width: s * 0.9, height: s * 0.7),
      centerHighlight,
    );

    final centerDot = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, bowCy), s * 0.25, centerDot);

    final tailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leftTail = Path()
      ..moveTo(cx - 1, bowCy + s * 0.3)
      ..cubicTo(cx - s * 0.5, bowCy + s * 1.5, cx - s * 1.0, bowCy + s * 2.0, cx - s * 1.3, bowCy + s * 2.8);
    canvas.drawPath(leftTail, tailPaint);

    final rightTail = Path()
      ..moveTo(cx + 1, bowCy + s * 0.3)
      ..cubicTo(cx + s * 0.5, bowCy + s * 1.5, cx + s * 1.0, bowCy + s * 2.0, cx + s * 1.3, bowCy + s * 2.8);
    canvas.drawPath(rightTail, tailPaint);
  }

  void _drawGlow(Canvas canvas, double w, double h, double cx, double cy, double t) {
    if (t < 0.25 || t > 0.85) return;
    final glowT = ((t - 0.25) / 0.6).clamp(0.0, 1.0);
    final glowOpacity = (glowT < 0.5 ? glowT * 2 : (1.0 - glowT) * 2).clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFD700).withValues(alpha: 0.3 * glowOpacity),
          Color(0xFFFFA000).withValues(alpha: 0.1 * glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: math.max(w, h) * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
  }

  void _drawConfetti(Canvas canvas, Size size, double cx, double cy, double ct) {
    if (ct <= 0) return;
    final rng = math.Random(7);
    final colors = [
      Color(0xFFFFD700),
      Color(0xFFFF6B6B),
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFFE53935),
      Colors.white,
    ];
    final confettiPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 50; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 100.0 + rng.nextDouble() * 200.0;
      final gravBend = (rng.nextDouble() - 0.5) * 80.0;
      final rotSpeed = (rng.nextDouble() - 0.5) * 14.0;
      final x = cx + math.cos(angle) * speed * ct + gravBend * ct * ct;
      final y = cy + math.sin(angle) * speed * ct - 80 * ct + 250 * ct * ct;
      final rot = ct * rotSpeed;
      final cw = 3.0 + rng.nextDouble() * 6.0;
      final ch = 2.0 + rng.nextDouble() * 4.0;
      final confettiOpacity = (1.0 - ct * 0.4).clamp(0.0, 1.0);
      confettiPaint.color = colors[i % colors.length].withValues(alpha: confettiOpacity);
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

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + t * math.pi * 0.8;
      final dist = (boxW * 0.3 + rng.nextDouble() * boxW * 0.4) * sparkT;
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist * 0.7;
      final sr = (1.5 + rng.nextDouble() * 2.5) * sparkleOpacity;
      final sparkleColors = [Color(0xFFFFD700), Colors.white, Color(0xFFFFF176)];
      sparklePaint.color = sparkleColors[i % sparkleColors.length].withValues(alpha: sparkleOpacity * 0.9);
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
  bool shouldRepaint(_LuxuryGiftPainter old) =>
      old.openProgress != openProgress || old.confettiProgress != confettiProgress;
}
