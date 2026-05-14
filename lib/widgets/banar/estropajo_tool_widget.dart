import 'package:flutter/material.dart';

class EstropajoToolWidget extends StatefulWidget {
  final bool enabled;
  final double size;

  const EstropajoToolWidget({
    super.key,
    required this.enabled,
    this.size = 48,
  });

  @override
  State<EstropajoToolWidget> createState() => _EstropajoToolWidgetState();
}

class _EstropajoToolWidgetState extends State<EstropajoToolWidget>
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
          painter: _EstropajoPainter(enabled: widget.enabled),
        ),
      ),
    );
  }
}

class _EstropajoPainter extends CustomPainter {
  final bool enabled;

  const _EstropajoPainter({required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final op = enabled ? 1.0 : 0.55;
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.75,
        height: h * 0.10,
      ),
      Paint()
        ..color = const Color(0xFF7A3E10).withValues(alpha: 0.18 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.56),
      width: w * 0.90,
      height: h * 0.56,
    );

    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD9894A).withValues(alpha: op),
            Color(0xFFC07030).withValues(alpha: op),
          ],
        ).createShader(bodyRect),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.53),
        width: w * 0.76,
        height: h * 0.43,
      ),
      Paint()..color = const Color(0xFFE89A52).withValues(alpha: 0.80 * op),
    );

    canvas.save();
    final clipPath = Path()..addOval(bodyRect);
    canvas.clipPath(clipPath);

    const cols = 9;
    const rows = 7;
    final left = bodyRect.left;
    final top = bodyRect.top;
    final right = bodyRect.right;
    final bottom = bodyRect.bottom;
    final stepX = (right - left) / cols;
    final stepY = (bottom - top) / rows;

    final hLinePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final vLinePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final diagPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int r = 0; r <= rows; r++) {
      final y = top + r * stepY;
      hLinePaint
        ..color = ((r.isEven
                    ? const Color(0xFF9A5018)
                    : const Color(0xFFB06030)))
                .withValues(alpha: 0.70 * op)
        ..strokeWidth = r.isEven ? 1.5 : 1.1;
      canvas.drawLine(Offset(left, y), Offset(right, y), hLinePaint);
    }

    for (int c = 0; c <= cols; c++) {
      final x = left + c * stepX;
      vLinePaint
        ..color = ((c.isEven
                    ? const Color(0xFF8A4412)
                    : const Color(0xFFA05820)))
                .withValues(alpha: 0.65 * op)
        ..strokeWidth = c.isEven ? 1.4 : 1.0;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), vLinePaint);
    }

    diagPaint.color = const Color(0xFF7A3E10).withValues(alpha: 0.38 * op);
    for (int i = -rows; i <= cols; i++) {
      final x0 = left + i * stepX;
      canvas.drawLine(
        Offset(x0, top),
        Offset(x0 + (rows * stepY), bottom),
        diagPaint,
      );
    }

    for (int i = 0; i <= cols + rows; i++) {
      final x0 = left + i * stepX;
      canvas.drawLine(
        Offset(x0, top),
        Offset(x0 - (rows * stepY), bottom),
        diagPaint,
      );
    }

    final knotPaintA =
        Paint()..color = const Color(0xFF6B3510).withValues(alpha: op);
    final knotPaintB =
        Paint()..color = const Color(0xFF5E2E0A).withValues(alpha: op);

    for (int r = 0; r <= rows; r++) {
      for (int c = 0; c <= cols; c++) {
        final x = left + c * stepX;
        final y = top + r * stepY;
        final radius = (r == rows ~/ 2 || c == cols ~/ 2) ? 2.6 : 2.0;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          (r + c).isEven ? knotPaintA : knotPaintB,
        );
      }
    }

    canvas.restore();

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.44),
        width: w * 0.36,
        height: h * 0.16,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.13 * op),
    );

    final foamPaint =
        Paint()..color = Colors.white.withValues(alpha: 0.82 * op);
    final foamData = [
      [w * 0.28, h * 0.30, w * 0.18, h * 0.11],
      [w * 0.50, h * 0.23, w * 0.15, h * 0.10],
      [w * 0.70, h * 0.28, w * 0.16, h * 0.10],
      [w * 0.40, h * 0.19, w * 0.11, h * 0.07],
      [w * 0.60, h * 0.18, w * 0.09, h * 0.06],
    ];
    for (final d in foamData) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d[0], d[1]),
          width: d[2] * 2,
          height: d[3] * 2,
        ),
        foamPaint,
      );
    }

    final bubblePaint = Paint()
      ..color = const Color(0xFFD4A8F5).withValues(alpha: 0.70 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final bubbleHighlight =
        Paint()..color = Colors.white.withValues(alpha: 0.50 * op);

    final bubbles = [
      [w * 0.10, h * 0.28, w * 0.09],
      [w * 0.88, h * 0.24, w * 0.10],
      [w * 0.92, h * 0.52, w * 0.06],
      [w * 0.06, h * 0.54, w * 0.05],
    ];
    for (final b in bubbles) {
      canvas.drawCircle(Offset(b[0], b[1]), b[2], bubblePaint);
      canvas.drawCircle(
        Offset(b[0] - b[2] * 0.3, b[1] - b[2] * 0.3),
        b[2] * 0.25,
        bubbleHighlight,
      );
    }

    final dropPaint =
        Paint()..color = const Color(0xFF8AD8FF).withValues(alpha: 0.62 * op);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.88),
        width: w * 0.07,
        height: h * 0.10,
      ),
      dropPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.66, h * 0.87),
        width: w * 0.06,
        height: h * 0.08,
      ),
      dropPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EstropajoPainter oldDelegate) {
    return oldDelegate.enabled != enabled;
  }
}
