import 'package:flutter/material.dart';
import 'package:ta3dia/services/pexels_background_service.dart';

class TaadiaBackground extends StatelessWidget {
  final Widget child;
  final bool showWatermark;

  const TaadiaBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return ValueListenableBuilder<String?>(
      valueListenable: PexelsBackgroundService.instance.imageUrlNotifier,
      builder: (context, pexelsUrl, _) {
        if (pexelsUrl != null) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    pexelsUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: cs.surface),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF3E3A36).withValues(alpha: 0.75)
                        : const Color(0xFFF5F0EB).withValues(alpha: 0.80),
                  ),
                ),
                Positioned.fill(child: child),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: isDark ? const Color(0xFF3E3A36) : const Color(0xFFF5F0EB),
          child: child,
        );
      },
    );
  }
}

class TaadiaHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const TaadiaHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
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
