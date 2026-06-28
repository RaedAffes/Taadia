import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ta3dia/main.dart' show AuthWrapper;

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeIn;
  Animation<double>? _scaleIn;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('splash_seen') != true;

    if (!firstLaunch) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthWrapper()),
      );
      return;
    }

    await prefs.setBool('splash_seen', true);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleIn = CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );
    _animationController!.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthWrapper()),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animationController == null) {
      return Scaffold(
        body: Container(color: Color(0xFFF5F0EB)),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFFF5F0EB),
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _IslamicGeometricPainter(),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: _HalftonePainter(),
            ),
            Positioned(
              top: -size.width * 0.35,
              right: -size.width * 0.35,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B7D6B).withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.25,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFA0937D).withValues(alpha: 0.04),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeIn!.value,
                    child: Transform.scale(
                      scale: _scaleIn!.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    SizedBox(height: 40),
                    _buildMainText(),
                    SizedBox(height: 20),
                    _buildSubtitle(),
                    SizedBox(height: 48),
                    _buildDecorativeDivider(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Size get size => MediaQuery.of(context).size;

  Widget _buildLogo() {
    return SizedBox(
      width: 120,
      height: 100,
      child: CustomPaint(
        size: Size(120, 100),
        painter: _MadinahSilhouettePainter(),
      ),
    );
  }

  Widget _buildMainText() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        'صل على محمد',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3E3A36),
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        'اللهم صل وسلم وبارك على سيدنا محمد',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 16,
          color: Color(0xFF8B7D6B),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDecorativeDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFA0937D).withValues(alpha: 0.3 + i * 0.1),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'TAADIA',
            style: TextStyle(
              color: Color(0xFFA0937D).withValues(alpha: 0.4),
              fontSize: 11,
              letterSpacing: 6,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFA0937D).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicGeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final primary = Color(0xFF8B7D6B).withValues(alpha: 0.06);
    final secondary = Color(0xFFA0937D).withValues(alpha: 0.04);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.sqrt(cx * cx + cy * cy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double r = 60;
    while (r < maxR) {
      final step = r * 0.35;
      paint.color = (r % 120 < 60) ? primary : secondary;
      _drawEightPointedStar(canvas, cx, cy, r, paint);
      r += step;
    }
  }

  void _drawEightPointedStar(
      Canvas canvas, double cx, double cy, double r, Paint paint) {
    const n = 8;
    final outer = <Offset>[];
    final inner = <Offset>[];

    for (int i = 0; i < n; i++) {
      final angle = (i * 2 * math.pi / n) - math.pi / 2;
      outer.add(Offset(
        cx + r * math.cos(angle),
        cy + r * math.sin(angle),
      ));
      final innerAngle = angle + math.pi / n;
      inner.add(Offset(
        cx + r * 0.4 * math.cos(innerAngle),
        cy + r * 0.4 * math.sin(innerAngle),
      ));
    }

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      canvas.drawLine(outer[i], inner[i], paint);
      canvas.drawLine(inner[i], outer[j], paint);
      canvas.drawLine(outer[i], outer[j], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HalftonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final spacing = 16.0;
    final dotPaint = Paint()..color = Color(0xFF8B7D6B).withValues(alpha: 0.04);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = math.sqrt(cx * cx + cy * cy);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final dist = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        final factor = 1 - (dist / maxDist);
        final radius = (1.5 + factor * 2.5).clamp(1.0, 4.0);
        final offsetX = (y / spacing % 2).round() * (spacing / 2);
        canvas.drawCircle(
          Offset(x + offsetX, y),
          radius.toDouble(),
          dotPaint..color = Color(0xFF8B7D6B).withValues(alpha: 0.02 + factor * 0.05),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MadinahSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cx = w / 2;

    // ---- Green Dome (القبة الخضراء) ----
    final domePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2E7D32),
          Color(0xFF1B5E20),
          Color(0xFF0D3B0F),
        ],
      ).createShader(Rect.fromLTWH(cx - 24, h * 0.15, 48, 50));

    // Dome body
    final domePath = Path();
    domePath.moveTo(cx - 24, h * 0.55);
    domePath.quadraticBezierTo(cx - 28, h * 0.35, cx - 16, h * 0.28);
    domePath.quadraticBezierTo(cx - 8, h * 0.18, cx, h * 0.15);
    domePath.quadraticBezierTo(cx + 8, h * 0.18, cx + 16, h * 0.28);
    domePath.quadraticBezierTo(cx + 28, h * 0.35, cx + 24, h * 0.55);
    domePath.close();
    canvas.drawPath(domePath, domePaint);

    // Dome spire (顶端)
    final spirePaint = Paint()..color = Color(0xFF8B7D6B);
    canvas.drawCircle(Offset(cx, h * 0.14), 2.5, spirePaint);
    canvas.drawLine(
      Offset(cx, h * 0.15),
      Offset(cx, h * 0.09),
      Paint()
        ..color = Color(0xFF8B7D6B)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(cx, h * 0.08), 1.5, spirePaint);

    // ---- Main building body ----
    final bodyPaint = Paint()..color = Color(0xFF8B7D6B).withValues(alpha: 0.6);
    final bodyPath = Path();
    bodyPath.moveTo(cx - 32, h * 0.55);
    bodyPath.lineTo(cx - 32, h * 0.85);
    bodyPath.lineTo(cx + 32, h * 0.85);
    bodyPath.lineTo(cx + 32, h * 0.55);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // ---- Arcades (رواق) ----
    final archPaint = Paint()
      ..color = Color(0xFFF5F0EB).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = -2; i <= 2; i++) {
      final ax = cx + i * 10;
      final archPath = Path();
      archPath.moveTo(ax - 3, h * 0.58);
      archPath.quadraticBezierTo(ax, h * 0.50, ax + 3, h * 0.58);
      canvas.drawPath(archPath, archPaint);
    }

    // ---- Minarets (مآذن) ----
    final minaretPaint = Paint()..color = Color(0xFF8B7D6B).withValues(alpha: 0.65);

    void drawMinaret(double x) {
      final mPath = Path();
      mPath.moveTo(x - 4, h * 0.55);
      mPath.lineTo(x - 4, h * 0.20);
      mPath.lineTo(x - 3, h * 0.20);
      mPath.lineTo(x - 3, h * 0.17);
      mPath.lineTo(x - 3.5, h * 0.15);
      mPath.lineTo(x - 2.5, h * 0.13);
      mPath.lineTo(x, h * 0.11);
      mPath.lineTo(x + 2.5, h * 0.13);
      mPath.lineTo(x + 3.5, h * 0.15);
      mPath.lineTo(x + 3, h * 0.17);
      mPath.lineTo(x + 3, h * 0.20);
      mPath.lineTo(x + 4, h * 0.20);
      mPath.lineTo(x + 4, h * 0.55);
      mPath.close();
      canvas.drawPath(mPath, minaretPaint);
    }

    drawMinaret(cx - 40);
    drawMinaret(cx + 40);

    // ---- Ground line ----
    canvas.drawLine(
      Offset(cx - 44, h * 0.85),
      Offset(cx + 44, h * 0.85),
      Paint()
        ..color = Color(0xFF8B7D6B).withValues(alpha: 0.4)
        ..strokeWidth = 1.0,
    );

    // ---- Dome glow ----
    final glowPaint = Paint()
      ..color = Color(0xFF2E7D32).withValues(alpha: 0.08);
    canvas.drawCircle(Offset(cx, h * 0.35), 28, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
