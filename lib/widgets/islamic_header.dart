import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _duas = [
  'رَبِّ زِدْنِي عِلْمًا – طه 114',
  'رَبِّ اشْرَحْ لِي صَدْرِي – طه 25',
  'وَيَسِّرْ لِي أَمْرِي – طه 26',
  'وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي – طه 27',
  'رَبِّ هَبْ لِي حُكْمًا – الشعراء 83',
  'وَأَلْحِقْنِي بِالصَّالِحِينَ – الشعراء 83',
  'وَاجْعَل لِّي لِسَانَ صِدْقٍ فِي الْآخِرِينَ – الشعراء 84',
  'وَاجْعَلْنِي مِن وَرَثَةِ جَنَّةِ النَّعِيمِ – الشعراء 85',
  'وَلَا تُخْزِنِي يَوْمَ يُبْعَثُونَ – الشعراء 87',
  'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ – الصافات 100',
  'رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً إِنَّكَ سَمِيعُ الدُّعَاءِ – آل عمران 38',
  'رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ – الأنبياء 89',
  'رَبِّ إِنِّي لَمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ – القصص 24',
  'رَبِّ مَسَّنِي الضَّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ – الأنبياء 83',
  'رَبِّ اغْفِرْ وَارْحَمْ وَأَنتَ خَيْرُ الرَّاحِمِينَ – المؤمنون 118',
  'رَبِّ اغْفِرْ لِي – الأعراف 151',
  'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ – إبراهيم 41',
  'رَبِّ اغْفِرْ لِي وَلِأَخِي وَأَدْخِلْنَا فِي رَحْمَتِكَ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ – الأعراف 151',
  'رَبِّ أَنزِلْنِي مَنزِلًا مُّبَارَكًا وَأَنتَ خَيْرُ الْمُنزِلِينَ – المؤمنون 29',
  'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ – المؤمنون 97',
  'وَأَعُوذُ بِكَ رَبِّ أَن يَحْضُرُونِ – المؤمنون 98',
  'رَبِّ نَجِّنِي مِنَ الْقَوْمِ الظَّالِمِينَ – القصص 21',
  'رَبِّ نَجِّنِي وَأَهْلِي مِمَّا يَعْمَلُونَ – الشعراء 169',
  'رَبِّ انصُرْنِي بِمَا كَذَّبُونِ – المؤمنون 26',
  'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنتَ السَّمِيعُ العَلِيمُ – البقرة 127',
  'وَتُبْ عَلَيْنَا إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ – البقرة 128',
  'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ – البقرة 201',
  'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ – آل عمران 8',
  'رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ – آل عمران 147',
  'رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ – آل عمران 193',
  'رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا – البقرة 286',
  'رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا – البقرة 286',
  'رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ – البقرة 286',
  'وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ – البقرة 286',
  'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ – البقرة 250',
  'رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْفَاتِحِينَ – الأعراف 89',
  'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ – الأعراف 126',
  'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ – الأعراف 23',
  'لَا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ – الأنبياء 87',
  'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ – النمل 19',
  'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأُصْلِحْ لِي فِي ذُرِّيَّتِي إِنِّي تُبْتُ إِلَيْكَ وَإِنِّي مِنَ الْمُسْلِمِينَ – الأحقاف 15',
  'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ – إبراهيم 40',
  'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ – إبراهيم 41',
  'رَبِّ اجْعَلْ هَذَا الْبَلَدَ آمِنًا وَاجْنُبْنِي وَبَنِيَّ أَن نَّعْبُدَ الْأَصْنَامَ – إبراهيم 35',
  'رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ – الممتحنة 4',
  'رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِّلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّنَا إِنَّكَ أَنتَ الْعَزِيزُ الْحَكِيمُ – الممتحنة 5',
];

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
  Size get preferredSize => Size.fromHeight(height);

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
      return _DotInfo(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
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
      if (dist < closestDist) {
        closestDist = dist;
        closest = dot;
      }
    }

    if (closest == null) return;

    final rng = math.Random();
    final popup = _VersePopup(
      id: _nextId++,
      text: _duas[rng.nextInt(_duas.length)],
      position: tapPos,
    );

    setState(() => _popups.add(popup));

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => popup.visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _popups.removeWhere((p) => p.id == popup.id));
      });
    });
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

        return Container(
          height: height,
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
                for (final popup in _popups)
                  Positioned(
                    left: (popup.position.dx - 70).clamp(0.0, size.width - 160),
                    top: (popup.position.dy < size.height * 0.4
                            ? popup.position.dy + 10
                            : popup.position.dy - 55)
                        .clamp(0.0, size.height - 80),
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
                  top: MediaQuery.of(context).padding.top + 4,
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
