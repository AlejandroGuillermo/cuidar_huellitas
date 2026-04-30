import 'package:flutter/material.dart';

class SoapToolWidget extends StatefulWidget {
  final bool enabled;
  final double size;

  const SoapToolWidget({
    super.key,
    required this.enabled,
    this.size = 48,
  });

  @override
  State<SoapToolWidget> createState() => _SoapToolWidgetState();
}

class _SoapToolWidgetState extends State<SoapToolWidget>
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SoapPainter(
            enabled: widget.enabled,
          ),
        ),
      ),
    );
  }
}

class _SoapPainter extends CustomPainter {
  final bool enabled;

  const _SoapPainter({required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = enabled ? 1.0 : 0.55;
    final w = size.width;
    final h = size.height;

    // ── Sombra del jabón ──────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0xFFB35ED6).withValues(alpha: 0.18 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.72,
        height: h * 0.12,
      ),
      shadowPaint,
    );

    // ── Cuerpo del jabón ──────────────────────────────────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.36, w * 0.84, h * 0.48),
      Radius.circular(w * 0.22),
    );

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE8B4F8).withValues(alpha: opacity),
        Color(0xFFD070EA).withValues(alpha: opacity),
      ],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Brillo lateral
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28 * opacity);
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.38, w * 0.30, h * 0.20),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(highlightRect, highlightPaint);

    // Línea decorativa
    final linePaint = Paint()
      ..color = const Color(0xFFB35ED6).withValues(alpha: 0.38 * opacity)
      ..strokeWidth = h * 0.030
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.20, h * 0.62),
      Offset(w * 0.80, h * 0.62),
      linePaint,
    );
    final linePaint2 = Paint()
      ..color = const Color(0xFFB35ED6).withValues(alpha: 0.20 * opacity)
      ..strokeWidth = h * 0.020
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.28, h * 0.70),
      Offset(w * 0.72, h * 0.70),
      linePaint2,
    );

    // ── Espuma encima del jabón ───────────────────────────────────────────────
    final foamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88 * opacity);

    final foamBlobs = [
      Offset(w * 0.30, h * 0.37),
      Offset(w * 0.50, h * 0.31),
      Offset(w * 0.68, h * 0.35),
      Offset(w * 0.42, h * 0.27),
      Offset(w * 0.58, h * 0.26),
    ];
    final foamRadii = [w * 0.16, w * 0.14, w * 0.15, w * 0.10, w * 0.09];

    for (int i = 0; i < foamBlobs.length; i++) {
      canvas.drawCircle(foamBlobs[i], foamRadii[i], foamPaint);
    }

    // ── Burbujas pequeñas flotando ────────────────────────────────────────────
    final bubblePaint = Paint()
      ..color = const Color(0xFFD4A8F5).withValues(alpha: 0.70 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bubbles = [
      _Bubble(Offset(w * 0.14, h * 0.22), w * 0.09),
      _Bubble(Offset(w * 0.82, h * 0.18), w * 0.11),
      _Bubble(Offset(w * 0.88, h * 0.42), w * 0.07),
      _Bubble(Offset(w * 0.10, h * 0.50), w * 0.06),
    ];

    for (final b in bubbles) {
      canvas.drawCircle(b.center, b.radius, bubblePaint);
      // pequeño brillo interior
      canvas.drawCircle(
        Offset(b.center.dx - b.radius * 0.3, b.center.dy - b.radius * 0.3),
        b.radius * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * opacity),
      );
    }

    // ── Gotitas de agua abajo ─────────────────────────────────────────────────
    final dropPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72 * opacity);

    _drawDrop(canvas, Offset(w * 0.30, h * 0.90), w * 0.040, h * 0.060, dropPaint);
    _drawDrop(canvas, Offset(w * 0.68, h * 0.88), w * 0.032, h * 0.048, dropPaint);
  }

  void _drawDrop(Canvas canvas, Offset center, double rx, double ry, Paint paint) {
    final path = Path();
    // gota = elipse levemente alargada
    path.addOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoapPainter old) =>
      old.enabled != enabled;
}

class _Bubble {
  final Offset center;
  final double radius;
  const _Bubble(this.center, this.radius);
}
