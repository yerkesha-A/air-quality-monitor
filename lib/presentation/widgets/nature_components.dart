import 'dart:ui';

import 'package:flutter/material.dart';

/// Visual tokens for the first, reviewable stage of the nature redesign.
abstract final class NatureStyle {
  static const forest = Color(0xff183e32);
  static const mint = Color(0xffd5e9da);
  static const milk = Color(0xfff4f6f2);
  static const ink = Color(0xff1c2924);
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: NatureStyle.forest,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: CustomPaint(painter: AirMarkPainter()),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIR',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
        borderRadius: BorderRadius.circular(26),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
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
