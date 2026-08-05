import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _VersePopup {
  final int id;
  final String text;
  final Offset position;
  bool visible;

  _VersePopup({
    required this.id,
    required this.text,
    required this.position,
    this.visible = true,
  });
}

class _DotInfo {
  double x, y;
  final double radius;
  double vx, vy;
  double maxX, maxY;

  _DotInfo({
    required this.x,
    required this.y,
    required this.radius,
    required this.vx,
    required this.vy,
    required this.maxX,
    required this.maxY,
  });

  void update(math.Random rng) {
    vx += (rng.nextDouble() - 0.5) * 0.002;
    vy += (rng.nextDouble() - 0.5) * 0.002;
    vx = vx.clamp(-0.06, 0.06);
    vy = vy.clamp(-0.05, 0.05);
    x += vx;
    y += vy;
    if (x < 0 || x > maxX) { vx = -vx * 0.5; x = x.clamp(0.0, maxX); }
    if (y < 0 || y > maxY) { vy = -vy * 0.5; y = y.clamp(0.0, maxY); }
    if (x < 80 && y < 60) {
      vx = (rng.nextDouble() * 0.04).abs();
      vy = (rng.nextDouble() * 0.04).abs();
      x = 80;
      y = 60;
    }
  }
}

class IslamicHeader extends StatefulWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(200);

  @override
  State<IslamicHeader> createState() => _IslamicHeaderState();
}

class _IslamicHeaderState extends State<IslamicHeader>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_VersePopup> _popups = [];
  int _nextId = 0;
  Size _headerSize = Size.zero;

  static const int _dotCount = 35;
  static const double _hitRadius = 30;
  final math.Random _rng = math.Random(42);
  List<_DotInfo>? _dots;

  // Smooth content transitions based on height
  double get _collapseProgress {
    final minH = 64.0;
    final maxH = 200.0;
    return ((maxH - widget.height) / (maxH - minH)).clamp(0.0, 1.0);
  }

  void _initDots(Size size) {
    _dots = List.generate(_dotCount, (_) {
      double x, y;
      do {
        x = _rng.nextDouble() * size.width;
        y = _rng.nextDouble() * size.height;
      } while (x < 80 && y < 60);
      return _DotInfo(
        x: x,
        y: y,
        radius: _rng.nextDouble() * 2.5 + 0.8,
        vx: (_rng.nextDouble() - 0.5) * 0.08,
        vy: (_rng.nextDouble() - 0.5) * 0.06,
        maxX: size.width,
        maxY: size.height,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_dots == null) return;
      setState(() {
        for (final dot in _dots!) {
          dot.update(_rng);
        }
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _getDotPosition(_DotInfo dot, Size size) {
    return Offset(dot.x, dot.y);
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final tapPos = details.localPosition;
    _DotInfo? closest;
    double closestDist = _hitRadius;

    for (final dot in _dots!) {
      final dist = (tapPos - _getDotPosition(dot, size)).distance;
      final effectiveRadius = (dot.x < 80 && dot.y < 60) ? 0.0 : _hitRadius;
      if (dist < effectiveRadius) {
        closestDist = dist;
        closest = dot;
      }
    }

    if (closest == null) return;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final height = widget.height;
    final cp = _collapseProgress;
    final titleFontSize = 24.0 - cp * 6.0;
    final subtitleOpacity = 1.0 - cp * 0.85;
    final dividerWidth = 50.0 - cp * 20.0;
    final contentTopPadding = (widget.leading != null || widget.actions != null)
        ? 52.0 - cp * 40.0
        : 24.0 - cp * 14.0;
    final contentBottomPadding = 20.0 - cp * 15.0;
    final spacingBeforeDivider = 12.0 - cp * 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, height);
        _headerSize = size;
        _dots ??= () {
          _initDots(size);
          return _dots;
        }();
        for (final dot in _dots!) {
          dot.maxX = size.width;
          dot.maxY = size.height;
        }

        return ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [cs.surface, cs.primary.withValues(alpha: 0.3), cs.primary]
                      : [cs.primary, const Color(0xFF6B5D4F), const Color(0xFF4A3F35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) => _onTapDown(d, size),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DotsPainter(
                      dots: _dots!,
                    ),
                  ),
                ),
                if (height > 100)
                  for (final popup in _popups)
                  Positioned(
                    left: (popup.position.dx - 70).clamp(0.0, math.max(0.0, size.width - 160)),
                    top: (popup.position.dy < size.height * 0.4
                            ? popup.position.dy + 10
                            : popup.position.dy - 55)
                        .clamp(0.0, math.max(0.0, size.height - 80)),
                    width: 160,
                    child: AnimatedSlide(
                      offset: popup.visible ? Offset.zero : const Offset(0, -0.4),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: popup.visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            popup.text,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: math.min(MediaQuery.of(context).padding.top + 4, widget.height - 48),
                  left: 0,
                  right: 0,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: Row(
                        children: [
                          if (widget.leading != null) widget.leading!,
                          const Spacer(),
                          if (widget.actions != null) ...[
                            ...widget.actions!,
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: contentTopPadding,
                      bottom: contentBottomPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty &&
                            subtitleOpacity > 0.05) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14 - cp * 2,
                              color: Colors.white.withValues(alpha: (0.85 * subtitleOpacity).clamp(0.0, 1.0)),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                        SizedBox(height: spacingBeforeDivider),
                        Container(
                          width: dividerWidth,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: (0.4 * (1.0 - cp * 0.7)).clamp(0.0, 1.0)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}

class _DotsPainter extends CustomPainter {
  final List<_DotInfo> dots;

  _DotsPainter({required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final dot in dots) {
      final speed = math.sqrt(dot.vx * dot.vx + dot.vy * dot.vy);
      final opacity = speed / 2.0;

      paint.color = Colors.white.withValues(alpha: 0.30 + opacity * 0.45);
      canvas.drawCircle(Offset(dot.x, dot.y), dot.radius * 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => true;
}
