import 'package:flutter/material.dart';

/// Widget de botiquín de primeros auxilios.
/// Uso:
///   BotiquinWidget(size: 200)
class BotiquinWidget extends StatelessWidget {
  final double size;

  const BotiquinWidget({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: CustomPaint(
        painter: _BotiquinPainter(),
      ),
    );
  }
}

class _BotiquinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Proporciones base (diseñado en 192×180 + extras) ──────────────
    final double bodyLeft   = w * 0.05;
    final double bodyTop    = h * 0.32;
    final double bodyWidth  = w * 0.90;
    final double bodyHeight = h * 0.60;
    final double radius     = w * 0.09;

    // ── Manija ────────────────────────────────────────────────────────
    final handlePaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final handleInnerPaint = Paint()
      ..color = const Color(0xFFEBEBEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(w * 0.30, bodyTop)
      ..quadraticBezierTo(w * 0.30, h * 0.10, w * 0.50, h * 0.10)
      ..quadraticBezierTo(w * 0.70, h * 0.10, w * 0.70, bodyTop);

    canvas.drawPath(handlePath, handlePaint);
    canvas.drawPath(handlePath, handleInnerPaint);

    // ── Bisagra izquierda ─────────────────────────────────────────────
    _drawHinge(canvas, Rect.fromLTWH(
      bodyLeft,
      bodyTop - h * 0.05,
      w * 0.09,
      h * 0.05,
    ));

    // ── Bisagra derecha ───────────────────────────────────────────────
    _drawHinge(canvas, Rect.fromLTWH(
      bodyLeft + bodyWidth - w * 0.09,
      bodyTop - h * 0.05,
      w * 0.09,
      h * 0.05,
    ));

    // ── Seguro / latch ────────────────────────────────────────────────
    final latchW = w * 0.26;
    final latchH = h * 0.07;
    final latchRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        w * 0.50 - latchW / 2,
        bodyTop - latchH - h * 0.01,
        latchW,
        latchH,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      latchRect,
      Paint()..color = const Color(0xFFD4D4D4),
    );
    canvas.drawRRect(
      latchRect,
      Paint()
        ..color = const Color(0xFFBEBEBE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Inner latch detail
    final innerLatchW = latchW * 0.67;
    final innerLatchH = latchH * 0.55;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.50 - innerLatchW / 2,
          bodyTop - latchH - h * 0.01 + latchH * 0.22,
          innerLatchW,
          innerLatchH,
        ),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = const Color(0xFFECECEC),
    );

    // ── Cuerpo principal ──────────────────────────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight),
      Radius.circular(radius),
    );

    canvas.drawRRect(
      bodyRect,
      Paint()..color = const Color(0xFFFAFAFA),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Franja roja superior ──────────────────────────────────────────
    final stripHeight = bodyHeight * 0.19;
    canvas.save();
    canvas.clipRRect(bodyRect);

    canvas.drawRect(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, stripHeight),
      Paint()..color = const Color(0xFFE85555),
    );

    // Sutil oscurecimiento en la parte inferior del cuerpo
    canvas.drawRect(
      Rect.fromLTWH(
        bodyLeft,
        bodyTop + bodyHeight - bodyHeight * 0.07,
        bodyWidth,
        bodyHeight * 0.07,
      ),
      Paint()..color = const Color(0xFFCC3F3F).withValues(alpha: 0.10),
    );

    canvas.restore();

    // ── Cruz roja ─────────────────────────────────────────────────────
    final crossCenterX = w * 0.50;
    final crossCenterY = bodyTop + bodyHeight * 0.58;
    final crossArmW    = w * 0.10;
    final crossArmH    = bodyHeight * 0.36;
    final crossR       = Radius.circular(w * 0.03);
    final crossRed     = Paint()..color = const Color(0xFFE85555);
    final crossWhite   = Paint()..color = Colors.white;

    // Vertical outer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmW + w * 0.06,
            height: crossArmH + w * 0.04),
        crossR,
      ),
      crossRed,
    );
    // Horizontal outer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmH + w * 0.04,
            height: crossArmW + w * 0.06),
        crossR,
      ),
      crossRed,
    );
    // Vertical white
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmW,
            height: crossArmH),
        crossR,
      ),
      crossWhite,
    );
    // Horizontal white
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmH,
            height: crossArmW),
        crossR,
      ),
      crossWhite,
    );
    // Center fill red
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmW * 0.55,
            height: crossArmH * 0.88),
        crossR,
      ),
      crossRed,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(crossCenterX, crossCenterY),
            width: crossArmH * 0.88,
            height: crossArmW * 0.55),
        crossR,
      ),
      crossRed,
    );

    // ── Píldoras decorativas ──────────────────────────────────────────
    final pillY = bodyTop + bodyHeight * 0.88;

    // Izquierda — rosada
    _drawPill(
      canvas,
      center: Offset(bodyLeft + bodyWidth * 0.15, pillY),
      rx: w * 0.055,
      ry: w * 0.030,
      angle: -0.35,
      color: const Color(0xFFF0A0A0).withValues(alpha: 0.65),
    );

    // Derecha — azul
    _drawPill(
      canvas,
      center: Offset(bodyLeft + bodyWidth * 0.85, pillY),
      rx: w * 0.055,
      ry: w * 0.030,
      angle: 0.35,
      color: const Color(0xFFA0C8F0).withValues(alpha: 0.65),
    );
  }

  void _drawHinge(Canvas canvas, Rect rect) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.3));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFFCACACA));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFFAAAAAA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawPill(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    required double angle,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
