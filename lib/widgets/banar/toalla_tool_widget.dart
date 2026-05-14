import 'dart:math' as math;
import 'package:flutter/material.dart';

class ToallaToolWidget extends StatefulWidget {
  final bool enabled;
  final double size;

  const ToallaToolWidget({
    super.key,
    required this.enabled,
    this.size = 48,
  });

  @override
  State<ToallaToolWidget> createState() => _ToallaToolWidgetState();
}

class _ToallaToolWidgetState extends State<ToallaToolWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ToallaPainter(enabled: widget.enabled),
        ),
      ),
    );
  }
}

class _ToallaPainter extends CustomPainter {
  final bool enabled;
  const _ToallaPainter({required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final op = enabled ? 1.0 : 0.50;
    final w = size.width;
    final h = size.height;

    final left = w * 0.10;
    final right = w * 0.90;
    final top = w * 0.30;
    final bottom = w * 0.78;
    final towelW = right - left;
    final towelH = bottom - top;
    final radius = w * 0.06;

    final towelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, towelW, towelH),
      Radius.circular(radius),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, bottom + h * 0.06),
        width: towelW * 0.85,
        height: h * 0.06,
      ),
      Paint()
        ..color = const Color(0xFF2E7A8A).withValues(alpha: 0.18 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left - w * 0.01,
          top + h * 0.01,
          towelW + w * 0.02,
          towelH,
        ),
        Radius.circular(radius),
      ),
      Paint()..color = const Color(0xFF2E7A8A).withValues(alpha: 0.30 * op),
    );

    canvas.drawRRect(
      towelRect,
      Paint()..color = const Color(0xFF4AACBE).withValues(alpha: op),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left + w * 0.01,
          top + h * 0.01,
          towelW - w * 0.02,
          towelH - h * 0.02,
        ),
        Radius.circular(radius - 1),
      ),
      Paint()..color = const Color(0xFF5ABECE).withValues(alpha: op),
    );

    canvas.save();
    canvas.clipRRect(towelRect);

    final fluffPaint = Paint()..strokeCap = StrokeCap.round;
    var lineY = top + h * 0.025;
    var thick = true;
    while (lineY < bottom - h * 0.01) {
      fluffPaint
        ..color = Colors.white.withValues(alpha: (thick ? 0.14 : 0.08) * op)
        ..strokeWidth = thick ? w * 0.012 : w * 0.007;
      canvas.drawLine(Offset(left, lineY), Offset(right, lineY), fluffPaint);
      lineY += h * 0.028;
      thick = !thick;
    }

    canvas.restore();

    final stripeH = towelH * 0.19;
    final stripePaint = Paint()
      ..color = const Color(0xFF2E8FA0).withValues(alpha: op);

    canvas.save();
    canvas.clipRRect(towelRect);
    canvas.drawRect(Rect.fromLTWH(left, top, towelW, stripeH), stripePaint);
    canvas.drawRect(
      Rect.fromLTWH(left, top + stripeH * 0.48, towelW, stripeH * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.28 * op),
    );
    canvas.drawRect(
      Rect.fromLTWH(left, bottom - stripeH, towelW, stripeH),
      stripePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        left,
        bottom - stripeH + stripeH * 0.30,
        towelW,
        stripeH * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28 * op),
    );
    canvas.restore();

    final stitchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38 * op)
      ..strokeWidth = w * 0.010
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(left + w * 0.04, top + stripeH + h * 0.016),
      Offset(right - w * 0.04, top + stripeH + h * 0.016),
      stitchPaint,
      dashLen: w * 0.04,
      gapLen: w * 0.03,
    );
    _drawDashedLine(
      canvas,
      Offset(left + w * 0.04, bottom - stripeH - h * 0.016),
      Offset(right - w * 0.04, bottom - stripeH - h * 0.016),
      stitchPaint,
      dashLen: w * 0.04,
      gapLen: w * 0.03,
    );

    final foldPath = Path()
      ..moveTo(left, top + stripeH)
      ..cubicTo(
        left + towelW * 0.30,
        top + stripeH + h * 0.030,
        left + towelW * 0.70,
        top + stripeH + h * 0.030,
        right,
        top + stripeH,
      );
    canvas.drawPath(
      foldPath,
      Paint()
        ..color = const Color(0xFF3A9AB0).withValues(alpha: 0.55 * op)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left + w * 0.04,
          top + h * 0.015,
          towelW * 0.34,
          towelH * 0.095,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.13 * op),
    );

    final steamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.010
      ..color = Colors.white.withValues(alpha: 0.32 * op);

    _drawSteam(
      canvas,
      Offset(w * 0.32, top - h * 0.02),
      h * 0.11,
      steamPaint,
    );
    _drawSteam(
      canvas,
      Offset(w * 0.50, top - h * 0.035),
      h * 0.13,
      steamPaint,
    );
    _drawSteam(
      canvas,
      Offset(w * 0.68, top - h * 0.02),
      h * 0.11,
      steamPaint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashLen,
    required double gapLen,
  }) {
    final total = (end - start).distance;
    final dir = (end - start) / total;
    var current = 0.0;
    while (current < total) {
      final dashStart = start + dir * current;
      final dashEnd = start + dir * math.min(current + dashLen, total);
      canvas.drawLine(dashStart, dashEnd, paint);
      current += dashLen + gapLen;
    }
  }

  void _drawSteam(Canvas canvas, Offset base, double height, Paint paint) {
    final path = Path()
      ..moveTo(base.dx, base.dy + height)
      ..cubicTo(
        base.dx - height * 0.10,
        base.dy + height * 0.70,
        base.dx + height * 0.10,
        base.dy + height * 0.35,
        base.dx,
        base.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToallaPainter oldDelegate) =>
      oldDelegate.enabled != enabled;
}
