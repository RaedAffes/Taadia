import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;

  const OnboardingStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon = Icons.info_outline,
    this.isLast = false,
  });
}

class OnboardingOverlay extends StatefulWidget {
  final List<OnboardingStep> steps;
  final String storageKey;
  final VoidCallback? onComplete;
  final bool autoShow;

  const OnboardingOverlay({
    super.key,
    required this.steps,
    required this.storageKey,
    this.onComplete,
    this.autoShow = true,
  });

  static Future<bool> shouldShow(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(storageKey) != true;
  }

  static Future<void> markSeen(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, true);
  }

  @override
  State<OnboardingOverlay> createState() => OnboardingOverlayState();
}

class OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _visible = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    if (widget.autoShow) {
      _autoShow();
    }
  }

  Future<void> _autoShow() async {
    if (!mounted) return;
    final should = await OnboardingOverlay.shouldShow(widget.storageKey);
    if (!should || !mounted) return;
    await Future.delayed(Duration(milliseconds: 600));
    if (!mounted) return;
    show();
  }

  void show() {
    if (!mounted) return;
    setState(() {
      _currentStep = 0;
      _visible = true;
    });
    _fadeController.forward();
    _scrollToTarget();
  }

  void showStep(int step) {
    if (!mounted || step >= widget.steps.length) return;
    setState(() {
      _currentStep = step;
      _visible = true;
    });
    _fadeController.forward();
    _scrollToTarget();
  }

  void hide() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _visible = false);
        OnboardingOverlay.markSeen(widget.storageKey);
        widget.onComplete?.call();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _scrollToTarget();
    } else {
      hide();
    }
  }

  void _scrollToTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = widget.steps[_currentStep].targetKey;
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.3,
        );
        _startScrollTracking();
      }
    });
  }

  void _startScrollTracking() {
    int ticks = 0;
    Timer.periodic(Duration(milliseconds: 30), (timer) {
      ticks++;
      if (!mounted || ticks > 20) {
        timer.cancel();
        if (mounted) setState(() {});
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect() {
    final key = widget.steps[_currentStep].targetKey;
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return null;
    final box = renderObject as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      pos.dx - 8,
      pos.dy - 8,
      box.size.width + 16,
      box.size.height + 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final step = widget.steps[_currentStep];
    final targetRect = _getTargetRect();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenRect = Rect.fromLTWH(0, 0, mq.size.width, mq.size.height);
          final highlightRect = targetRect ?? screenRect.center & Size(200, 50);

          return Stack(
            children: [
              GestureDetector(
                onTap: hide,
                child: CustomPaint(
                  size: Size(mq.size.width, mq.size.height),
                  painter: _OverlayPainter(
                    highlightRect: highlightRect,
                    borderColor: Colors.white,
                  ),
                ),
              ),
              _buildTooltip(
                step: step,
                highlightRect: highlightRect,
                screenSize: mq.size,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTooltip({
    required OnboardingStep step,
    required Rect highlightRect,
    required Size screenSize,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tooltipWidth = math.min(screenSize.width - 48, 340.0);

    final topSpace = highlightRect.top;
    final bottomSpace = screenSize.height - highlightRect.bottom;
    final showAbove = topSpace > 150 && topSpace > bottomSpace;

    double left = (screenSize.width - tooltipWidth) / 2;
    left = left.clamp(16.0, screenSize.width - tooltipWidth - 16.0);

    double top;
    if (showAbove) {
      top = highlightRect.top - 170;
      if (top < 16) top = 16;
    } else {
      top = highlightRect.bottom + 16;
      if (top + 160 > screenSize.height) {
        top = screenSize.height - 170;
      }
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Positioned(
      top: top,
      left: left,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, size: 20, color: cs.onPrimary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${_currentStep + 1}/${widget.steps.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(width: 8),
                  ...List.generate(widget.steps.length, (i) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      width: i == _currentStep ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentStep
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  Spacer(),
                  if (!step.isLast)
                    FilledButton.tonal(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isRtl ? 'حسناً' : 'OK',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: hide,
                      style: FilledButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isRtl ? 'ابدأ' : 'Start',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect highlightRect;
  final Color borderColor;

  _OverlayPainter({required this.highlightRect, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(highlightRect, Radius.circular(16)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(16)),
      borderPaint,
    );

    final glowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(16)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      highlightRect != old.highlightRect;
}
