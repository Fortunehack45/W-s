import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tokens.dart';

/// Formatting utilities for W's platform currency.
class WsCurrency {
  static const String symbol = '₩';

  static String format(num amount) {
    final formatter = NumberFormat('#,##0.0');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(num amount) {
    final formatter = NumberFormat.compact();
    return '$symbol${formatter.format(amount)}';
  }

  static String formatWhole(num amount) {
    final formatter = NumberFormat('#,###');
    return '$symbol${formatter.format(amount)}';
  }
}

/// The official signature W's Sign vector painter and icon widget.
/// Inspired by the sleek Aura ₳ glyph in Giggles, but crafted specifically for W's.
class WsGlyph extends StatelessWidget {
  const WsGlyph({
    this.size = 24.0,
    this.color = WsTokens.brandGold,
    this.hasGlow = true,
    this.strokeWidth = 2.4,
    super.key,
  });

  final double size;
  final Color color;
  final bool hasGlow;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WsGlyphPainter(
          color: color,
          hasGlow: hasGlow,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _WsGlyphPainter extends CustomPainter {
  _WsGlyphPainter({
    required this.color,
    required this.hasGlow,
    required this.strokeWidth,
  });

  final Color color;
  final bool hasGlow;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..strokeWidth = strokeWidth * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
        ..style = PaintingStyle.stroke;

      _drawWPath(canvas, w, h, glowPaint);
      _drawCrossbars(canvas, w, h, glowPaint);
    }

    _drawWPath(canvas, w, h, paint);
    _drawCrossbars(canvas, w, h, paint);
  }

  void _drawWPath(Canvas canvas, double w, double h, Paint paint) {
    final path = Path()
      ..moveTo(w * 0.12, h * 0.18)
      ..lineTo(w * 0.32, h * 0.84)
      ..lineTo(w * 0.50, h * 0.36)
      ..lineTo(w * 0.68, h * 0.84)
      ..lineTo(w * 0.88, h * 0.18);

    canvas.drawPath(path, paint);
  }

  void _drawCrossbars(Canvas canvas, double w, double h, Paint paint) {
    // Top horizontal crossbar cutting through the W
    canvas.drawLine(
      Offset(w * 0.06, h * 0.44),
      Offset(w * 0.94, h * 0.44),
      paint,
    );

    // Bottom horizontal crossbar for double-barred currency identity
    canvas.drawLine(
      Offset(w * 0.14, h * 0.58),
      Offset(w * 0.86, h * 0.58),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WsGlyphPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.hasGlow != hasGlow ||
      oldDelegate.strokeWidth != strokeWidth;
}
