import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn style illustration: shared table + dishes + friend avatars.
/// Replaces the emoji stack — pure Flutter, no network assets.
class FoodCrewIllustration extends StatefulWidget {
  const FoodCrewIllustration({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  final double size;
  final bool animate;

  @override
  State<FoodCrewIllustration> createState() => _FoodCrewIllustrationState();
}

class _FoodCrewIllustrationState extends State<FoodCrewIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.animate) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!widget.animate || reduceMotion) {
      return SizedBox(
        width: widget.size,
        height: widget.size * 0.78,
        child: CustomPaint(
          painter: _FoodCrewPainter(scheme: scheme, t: 0.5),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.78,
          child: CustomPaint(
            painter: _FoodCrewPainter(scheme: scheme, t: _ctrl.value),
          ),
        );
      },
    );
  }
}

class _FoodCrewPainter extends CustomPainter {
  _FoodCrewPainter({required this.scheme, required this.t});

  final ColorScheme scheme;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bob = math.sin(t * math.pi) * 3.0;

    // Soft ground glow
    final glow = Paint()
      ..color = scheme.primary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.78),
        width: w * 0.72,
        height: h * 0.18,
      ),
      glow,
    );

    // Table top
    final table = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.52 + bob * 0.2, w * 0.76, h * 0.14),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      table,
      Paint()..color = scheme.primary.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      table,
      Paint()
        ..color = scheme.primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Center platter
    final plateCenter = Offset(w * 0.5, h * 0.48 + bob);
    canvas.drawCircle(
      plateCenter,
      w * 0.14,
      Paint()..color = scheme.surface,
    );
    canvas.drawCircle(
      plateCenter,
      w * 0.14,
      Paint()
        ..color = scheme.primary.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Food wedges on plate
    final wedgePaint = Paint()..color = scheme.primary;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * (math.pi * 2 / 5);
      final r = w * 0.07;
      final p = plateCenter + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55);
      canvas.drawCircle(p, w * 0.028, wedgePaint..color = _foodColor(i, scheme));
    }

    // Side bowls
    _bowl(canvas, Offset(w * 0.28, h * 0.50 + bob * 0.6), w * 0.07, scheme.tertiary);
    _bowl(canvas, Offset(w * 0.72, h * 0.50 + bob * 0.4), w * 0.07, scheme.secondary);

    // Friend avatars around table
    _friend(
      canvas,
      Offset(w * 0.22, h * 0.28 + bob),
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
      'A',
    );
    _friend(
      canvas,
      Offset(w * 0.5, h * 0.18 - bob),
      scheme.tertiaryContainer,
      scheme.onTertiaryContainer,
      'S',
    );
    _friend(
      canvas,
      Offset(w * 0.78, h * 0.28 + bob * 0.5),
      scheme.secondaryContainer,
      scheme.onSecondaryContainer,
      'J',
    );

    // Steam lines from plate
    final steam = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = plateCenter.dx - 10 + i * 10.0;
      final path = Path()
        ..moveTo(x, plateCenter.dy - w * 0.14)
        ..cubicTo(
          x + 4,
          plateCenter.dy - w * 0.18 - bob,
          x - 4,
          plateCenter.dy - w * 0.22 - bob,
          x,
          plateCenter.dy - w * 0.26 - bob,
        );
      canvas.drawPath(path, steam);
    }
  }

  Color _foodColor(int i, ColorScheme scheme) {
    const extras = [
      Color(0xFFFF6B4A),
      Color(0xFFFFB347),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
      Color(0xFFF15BB5),
    ];
    return extras[i % extras.length];
  }

  void _bowl(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c + Offset(0, -r * 0.15),
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _friend(
    Canvas canvas,
    Offset c,
    Color bg,
    Color fg,
    String letter,
  ) {
    canvas.drawCircle(
      c,
      22,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(c, 20, Paint()..color = bg);
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FoodCrewPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.scheme != scheme;
}
