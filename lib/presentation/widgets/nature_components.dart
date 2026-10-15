import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual tokens for the first, reviewable stage of the nature redesign.
abstract final class NatureStyle {
  static const forest = Color(0xff285964);
  static const mint = Color(0xffd5eaf0);
  static const milk = Color(0xfff3f7f9);
  static const ink = Color(0xff1d3540);
  static const alpineLake = 'assets/images/alpine_clouds.webp';
  static const blueMountains = 'assets/images/blue_mountains.webp';
  static const mistyHills = 'assets/images/misty_hills.webp';
  static const forestSun = 'assets/images/forest_sun.webp';
  static const forestMist = 'assets/images/forest_mist.webp';
}

class AirWordmark extends StatelessWidget {
  const AirWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'Air Quality',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIR',
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'quality',
                  style: TextStyle(
                    color: color.withValues(alpha: .65),
                    fontSize: 12,
                    letterSpacing: 1.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The same three air currents are used by the native Android launcher icon.
class AirMarkPainter extends CustomPainter {
  const AirMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final paint = Paint()
      ..color = NatureStyle.mint
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(2, 10)
      ..lineTo(21, 10)
      ..cubicTo(30, 10, 30, 1, 23, 2)
      ..moveTo(2, 17)
      ..lineTo(26, 17)
      ..cubicTo(33, 17, 33, 27, 26, 27)
      ..moveTo(2, 24)
      ..lineTo(15, 24)
      ..cubicTo(22, 24, 22, 32, 16, 31);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AirMarkPainter oldDelegate) => false;
}

/// One bounded blur per photographic hero, rather than blur on every list item.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.tint = NatureStyle.forest,
    this.grouped = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color tint;
  final bool grouped;
  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: .70), tint.withValues(alpha: .52)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: grouped
          ? BackdropFilter.grouped(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: content,
            )
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: content,
            ),
    );
  }
}

class QuietIconButton extends StatelessWidget {
  const QuietIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    icon: Icon(icon, size: 22),
  );
}

/// Lightweight frosted surfaces over a quiet background, without per-tile blur.
class AirSurface extends StatelessWidget {
  const AirSurface({
    super.key,
    required this.child,
    this.accent = const Color(0xffb9dce9),
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff275b75).withValues(alpha: dark ? .12 : .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [const Color(0xff254451), const Color(0xff1a303e)]
                  : [
                      Colors.white.withValues(alpha: .86),
                      Color.lerp(
                        Colors.white,
                        accent,
                        .6,
                      )!.withValues(alpha: .78),
                    ],
            ),
            border: Border.all(
              color: dark ? Colors.white12 : Colors.white.withValues(alpha: .9),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AtmosphereHeader extends StatelessWidget {
  const AtmosphereHeader({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            NatureStyle.blueMountains,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 1000,
            excludeFromSemantics: true,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xb321485e), Color(0x88255966)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// Shared native scaffold: local photography, legible milky veil and an opaque
/// dark-mode veil. The Scaffold still owns insets, keyboard and navigation.
class AirScaffold extends StatelessWidget {
  const AirScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.immersive = false,
  });
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final bool immersive;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: Stack(
      children: [
        Positioned.fill(child: AirBackdrop(immersive: immersive)),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ],
    ),
  );
}

class AirBackdrop extends StatelessWidget {
  const AirBackdrop({super.key, this.immersive = false});
  final bool immersive;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            immersive ? NatureStyle.alpineLake : NatureStyle.blueMountains,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 1000,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [const Color(0xd9102b39), const Color(0xf2112631)]
                    : immersive
                    ? [
                        const Color(0x99e1f2f8),
                        const Color(0x66eaf5f9),
                        const Color(0xe6e1edf2),
                      ]
                    : [
                        const Color(0xbbe0f3fa),
                        const Color(0xe6e5f1f5),
                        const Color(0xf2e6f0f4),
                      ],
                stops: dark ? null : const [0, .48, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandscapeAvatar extends StatelessWidget {
  const LandscapeAvatar({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      NatureStyle.alpineLake,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: 160,
      excludeFromSemantics: true,
    ),
  );
}
