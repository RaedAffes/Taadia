import 'dart:math' as math;
import 'package:flutter/material.dart';

class GiftRevealCard extends StatefulWidget {
  final Widget child;
  final bool showGift;
  final Duration delay;
  final VoidCallback? onRevealed;

  const GiftRevealCard({
    super.key,
    required this.child,
    this.showGift = false,
    this.delay = const Duration(milliseconds: 500),
    this.onRevealed,
  });

  @override
  State<GiftRevealCard> createState() => _GiftRevealCardState();
}

class _GiftRevealCardState extends State<GiftRevealCard>
    with TickerProviderStateMixin {
  late AnimationController _openController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _openController, curve: Curves.elasticOut),
    );

    _openController.addListener(() { if (mounted) setState(() {}); });
    _sparkleController.addListener(() { if (mounted) setState(() {}); });

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
    _sparkleController.repeat();
    await Future.delayed(widget.delay);
    if (!mounted) return;
    await _openController.forward();
    _sparkleController.stop();
    if (mounted) {
      setState(() => _revealed = true);
      widget.onRevealed?.call();
    }
  }

  @override
  void dispose() {
    _openController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showGift || _revealed) {
      return widget.child;
    }

    return Stack(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
        if (_openController.value < 0.95) _buildGiftOverlay(),
      ],
    );
  }

  Widget _buildGiftOverlay() {
    final openProgress = _openController.value;

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: (1.0 - openProgress).clamp(0.0, 1.0),
        duration: Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFF5D76E),
                Color(0xFFD4AF37),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4AF37).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _GiftPainter(openProgress: openProgress),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: openProgress * 0.3,
                    child: Icon(
                      Icons.redeem,
                      size: 48,
                      color: Colors.white.withValues(alpha: (1.0 - openProgress).clamp(0.0, 1.0)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🎁',
                    style: TextStyle(
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class _GiftPainter extends CustomPainter {
  final double openProgress;

  _GiftPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final ribbonPaint = Paint()
      ..color = Color(0xFFB22222)
      ..style = PaintingStyle.fill;

    final ribbonWidth = 12.0;

    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - ribbonWidth) / 2,
        0,
        ribbonWidth,
        size.height,
      ),
      ribbonPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        (size.height - ribbonWidth) / 2,
        size.width,
        ribbonWidth,
      ),
      ribbonPaint,
    );

    final bowPaint = Paint()
      ..color = Color(0xFFB22222)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final bowSize = 16.0 + openProgress * 8;

    final leftBow = Path()
      ..moveTo(centerX, centerY)
      ..quadraticBezierTo(
        centerX - bowSize,
        centerY - bowSize * 1.2,
        centerX - bowSize * 0.3,
        centerY - bowSize * 1.5,
      )
      ..quadraticBezierTo(
        centerX,
        centerY - bowSize * 0.5,
        centerX,
        centerY,
      );
    canvas.drawPath(leftBow, bowPaint);

    final rightBow = Path()
      ..moveTo(centerX, centerY)
      ..quadraticBezierTo(
        centerX + bowSize,
        centerY - bowSize * 1.2,
        centerX + bowSize * 0.3,
        centerY - bowSize * 1.5,
      )
      ..quadraticBezierTo(
        centerX,
        centerY - bowSize * 0.5,
        centerX,
        centerY,
      );
    canvas.drawPath(rightBow, bowPaint);

    final knotPaint = Paint()
      ..color = Color(0xFF8B0000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 5, knotPaint);

    final goldPaint = Paint()
      ..color = Color(0xFFDAA520).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final sparkleRng = math.Random(42);
    final sparkleOpacity = (1.0 - openProgress).clamp(0.0, 1.0);
    for (int i = 0; i < 12; i++) {
      final x = sparkleRng.nextDouble() * size.width;
      final y = sparkleRng.nextDouble() * size.height;
      final r = sparkleRng.nextDouble() * 2 + 1;
      goldPaint.color = Color(0xFFDAA520).withValues(
        alpha: sparkleOpacity * (sparkleRng.nextDouble() * 0.5 + 0.3),
      );
      canvas.drawCircle(Offset(x, y), r, goldPaint);
    }
  }

  @override
  bool shouldRepaint(_GiftPainter old) => old.openProgress != openProgress;
}
