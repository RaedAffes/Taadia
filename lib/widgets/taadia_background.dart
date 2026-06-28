import 'package:flutter/material.dart';

class TaadiaBackground extends StatelessWidget {
  final Widget child;
  final bool showWatermark;
  final String? backgroundImage;

  const TaadiaBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            backgroundImage ?? 'assets/images/taadia image.png',
          ),
          fit: BoxFit.cover,
          opacity: isDark ? 0.08 : 0.12,
        ),
      ),
      child: child,
    );
  }
}

class TaadiaHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final double imageHeight;
  final String? imagePath;

  const TaadiaHeader({
    super.key,
    this.title,
    this.subtitle,
    this.imageHeight = 120,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imagePath ?? 'assets/images/taadia image.png',
            height: imageHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.task_alt,
              size: imageHeight * 0.6,
              color: cs.primary,
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class TaadiaFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const TaadiaFormCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
