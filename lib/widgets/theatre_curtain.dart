import 'dart:math' as math;
import 'package:flutter/material.dart';

class TheatreCurtainReveal extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRevealed;
  final Duration pauseDuration;
  final Duration animationDuration;
  final bool showImmediately;

  const TheatreCurtainReveal({
    super.key,
    required this.child,
    this.onRevealed,
    this.pauseDuration = const Duration(milliseconds: 800),
    this.animationDuration = const Duration(milliseconds: 1200),
    this.showImmediately = true,
  });

  @override
  State<TheatreCurtainReveal> createState() => _TheatreCurtainRevealState();
}

class _TheatreCurtainRevealState extends State<TheatreCurtainReveal>
    with TickerProviderStateMixin {
  late AnimationController _curtainController;
  late AnimationController _glitterController;
  late Animation<double> _curtainAnimation;
  late Animation<double> _shimmerAnimation;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _curtainController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _curtainAnimation = CurvedAnimation(
      parent: _curtainController,
      curve: Curves.easeInOutCubic,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _glitterController, curve: Curves.linear),
    );

    _curtainController.addListener(() {
      if (mounted) setState(() {});
    });
    _glitterController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.showImmediately) {
      _startSequence();
    }
  }

  Future<void> _startSequence() async {
    _glitterController.repeat();
    await Future.delayed(widget.pauseDuration);
    if (mounted) {
      await _curtainController.forward();
      _glitterController.stop();
      if (mounted) {
        setState(() => _revealed = true);
        widget.onRevealed?.call();
      }
    }
  }

  @override
  void dispose() {
    _curtainController.dispose();
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_revealed) _buildCurtainOverlay(),
      ],
    );
  }

  Widget _buildCurtainOverlay() {
    return CustomPaint(
      painter: _CurtainPainter(
        openFraction: _curtainAnimation.value,
        shimmerPosition: _shimmerAnimation.value,
        shimmerActive: _glitterController.isAnimating,
      ),
      size: Size.infinite,
    );
  }
}

class _CurtainPainter extends CustomPainter {
  final double openFraction;
  final double shimmerPosition;
  final bool shimmerActive;

  _CurtainPainter({
    required this.openFraction,
    required this.shimmerPosition,
    this.shimmerActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (openFraction >= 1.0) return;

    final halfWidth = size.width / 2;
    final openOffset = halfWidth * openFraction;

    _drawCurtainHalf(
      canvas,
      size,
      isLeft: true,
      openOffset: openOffset,
    );
    _drawCurtainHalf(
      canvas,
      size,
      isLeft: false,
      openOffset: openOffset,
    );

    _drawTopDrape(canvas, size, openFraction);
    _drawTassels(canvas, size, openOffset);

    if (shimmerActive && openFraction < 0.5) {
      _drawShimmer(canvas, size);
    }
  }

  void _drawTopDrape(Canvas canvas, Size size, double openFraction) {
    final opacity = (1.0 - openFraction).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final drapePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8B0000).withValues(alpha: opacity),
          Color(0xFFB22222).withValues(alpha: opacity * 0.8),
          Color(0xFFB22222).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 60));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 60)
      ..quadraticBezierTo(size.width * 0.75, 40, size.width * 0.5, 45)
      ..quadraticBezierTo(size.width * 0.25, 50, 0, 35)
      ..close();

    canvas.drawPath(path, drapePaint);

    final goldPaint = Paint()
      ..color = Color(0xFFDAA520).withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fringePath = Path();
    final fringeCount = 20;
    for (int i = 0; i < fringeCount; i++) {
      final x = (size.width / fringeCount) * i + 8;
      final startY = 35.0 + (i / fringeCount) * 10;
      final wobble = math.sin(i * 0.8) * 3;
      fringePath.moveTo(x, startY + wobble);
      fringePath.lineTo(x + wobble * 0.5, startY + 12 + wobble);
    }
    canvas.drawPath(fringePath, goldPaint);
  }

  void _drawCurtainHalf(
    Canvas canvas,
    Size size, {
    required bool isLeft,
    required double openOffset,
  }) {
    final baseColor = Color(0xFF8B0000);
    final highlightColor = Color(0xFFB22222);
    final shadowColor = Color(0xFF5C0000);

    final path = Path();
    final foldCount = 8;
    final curtainEdge = isLeft ? openOffset : (size.width - openOffset);
    final curtainWidth = isLeft ? curtainEdge : (size.width - curtainEdge);

    if (curtainWidth < 2) return;

    final foldWidth = curtainWidth / foldCount;

    if (isLeft) {
      path.moveTo(curtainEdge, 0);
      for (int i = foldCount; i >= 0; i--) {
        final baseX = curtainEdge - (foldWidth * (foldCount - i));
        final wobble = math.sin(i * 0.9 + openFraction * 4) * (12 - openFraction * 10);
        final y = (size.height * (i / foldCount));
        final bulge = math.sin((i / foldCount) * math.pi) * foldWidth * 0.4;

        path.quadraticBezierTo(
          baseX - bulge,
          y - foldWidth * 0.2 + wobble,
          baseX,
          y + wobble,
        );
      }
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(curtainEdge, 0);
      for (int i = foldCount; i >= 0; i--) {
        final baseX = curtainEdge + (foldWidth * (foldCount - i));
        final wobble = math.sin(i * 0.9 + openFraction * 4) * (12 - openFraction * 10);
        final y = (size.height * (i / foldCount));
        final bulge = math.sin((i / foldCount) * math.pi) * foldWidth * 0.4;

        path.quadraticBezierTo(
          baseX + bulge,
          y - foldWidth * 0.2 + wobble,
          baseX,
          y + wobble,
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    final gradient = LinearGradient(
      begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      colors: [
        highlightColor,
        baseColor,
        shadowColor,
      ],
      stops: [0.0, 0.4, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);

    if (shimmerActive) {
      final shimmerRect = Rect.fromLTWH(
        0,
        size.height * ((shimmerPosition % 1.0)),
        size.width,
        size.height * 0.25,
      );
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(shimmerRect);
      canvas.drawPath(path, shimmerPaint);
    }

    final edgePaint = Paint()
      ..color = Color(0xFF3D0000).withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final edgePath = Path();
    edgePath.moveTo(curtainEdge, 0);
    for (int i = foldCount; i >= 0; i--) {
      final baseX = isLeft
          ? curtainEdge - (foldWidth * (foldCount - i))
          : curtainEdge + (foldWidth * (foldCount - i));
      final wobble = math.sin(i * 0.9 + openFraction * 4) * (12 - openFraction * 10);
      final y = (size.height * (i / foldCount));
      final bulge = math.sin((i / foldCount) * math.pi) * foldWidth * 0.4;

      edgePath.quadraticBezierTo(
        isLeft ? baseX - bulge : baseX + bulge,
        y - foldWidth * 0.2 + wobble,
        baseX,
        y + wobble,
      );
    }
    canvas.drawPath(edgePath, edgePaint);

    final foldShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i < foldCount; i++) {
      final baseX = isLeft
          ? curtainEdge - (foldWidth * (foldCount - i))
          : curtainEdge + (foldWidth * (foldCount - i));

      foldShadowPaint.color = Color(0x33000000);
      final foldPath = Path();
      foldPath.moveTo(baseX, 0);
      foldPath.lineTo(baseX, size.height);
      canvas.drawPath(foldPath, foldShadowPaint);

      final highlightPath = Path();
      final highlightX = isLeft ? baseX + 3 : baseX - 3;
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      highlightPath.moveTo(highlightX, 0);
      highlightPath.lineTo(highlightX, size.height);
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  void _drawTassels(Canvas canvas, Size size, double openOffset) {
    if (openFraction > 0.6) return;

    final alpha = (1.0 - openFraction / 0.6).clamp(0.0, 1.0);

    final tasselPaint = Paint()
      ..color = Color(0xFFDAA520).withValues(alpha: alpha)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final knotPaint = Paint()
      ..color = Color(0xFFDAA520).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final cordPaint = Paint()
      ..color = Color(0xFFB8860B).withValues(alpha: alpha * 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawTassel(canvas, openOffset + 18, 48, tasselPaint, knotPaint, cordPaint);
    _drawTassel(canvas, size.width - openOffset - 18, 48, tasselPaint, knotPaint, cordPaint);
  }

  void _drawTassel(Canvas canvas, double x, double y, Paint tasselPaint,
      Paint knotPaint, Paint cordPaint) {
    canvas.drawCircle(Offset(x, y), 5, knotPaint);

    canvas.drawCircle(Offset(x, y), 5, Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    final cordPath = Path()
      ..moveTo(x, y + 5)
      ..quadraticBezierTo(x + 3, y + 10, x, y + 18);
    canvas.drawPath(cordPath, cordPaint);

    for (int i = -2; i <= 2; i++) {
      final strandX = x + i * 2.5;
      final strandPath = Path()
        ..moveTo(x, y + 14)
        ..quadraticBezierTo(strandX, y + 22, strandX + i * 0.5, y + 30 + (i.abs() * 2));
      canvas.drawPath(strandPath, tasselPaint);
    }
  }

  void _drawShimmer(Canvas canvas, Size size) {
    final shimmerPaint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    final sparkleOpacity = (1.0 - openFraction * 2).clamp(0.0, 1.0);

    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 2.5 + 0.5;
      final phase = (shimmerPosition + random.nextDouble()) % 1.0;
      final twinkle = (math.sin(phase * math.pi * 2) * 0.5 + 0.5);

      shimmerPaint.color = Color(0xFFDAA520).withValues(
        alpha: sparkleOpacity * twinkle * 0.6,
      );
      canvas.drawCircle(Offset(x, y), r, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(_CurtainPainter oldDelegate) =>
      oldDelegate.openFraction != openFraction ||
      oldDelegate.shimmerPosition != shimmerPosition ||
      oldDelegate.shimmerActive != shimmerActive;
}
