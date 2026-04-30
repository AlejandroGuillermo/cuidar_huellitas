import 'package:flutter/material.dart';

class ArmarioWidget extends StatefulWidget {
  final double maxHeight;
  const ArmarioWidget({super.key, required this.maxHeight});

  @override
  State<ArmarioWidget> createState() => _ArmarioWidgetState();
}

class _ArmarioWidgetState extends State<ArmarioWidget>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  bool _busy = false;

  late final AnimationController _doorCtrl;
  late final AnimationController _itemsCtrl;
  late final Animation<double> _doorAnim;
  late final Animation<double> _itemsAnim;

  @override
  void initState() {
    super.initState();

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _doorAnim = CurvedAnimation(
      parent: _doorCtrl,
      curve: Curves.easeInOut,
    );

    _itemsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _itemsAnim = CurvedAnimation(
      parent: _itemsCtrl,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _doorCtrl.dispose();
    _itemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    _busy = true;

    if (!_isOpen) {
      _itemsCtrl.reverse();
      await _doorCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      _itemsCtrl.forward();
    } else {
      await _itemsCtrl.reverse();
      await _doorCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 540),
        curve: _ReboteCurve(),
      );
    }

    if (mounted) setState(() => _isOpen = !_isOpen);
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.maxHeight.clamp(110.0, 350.0);
    final w = h * 0.74;

    return GestureDetector(
      onTap: _toggle,
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: Listenable.merge([_doorAnim, _itemsAnim]),
          builder: (_, _) => CustomPaint(
            painter: _ArmarioPainter(
              doorOpen: _doorAnim.value,
              itemsOpacity: _itemsAnim.value,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ReboteCurve extends Curve {
  @override
  double transformInternal(double t) {
    if (t < 0.75) return t / 0.75;
    final r = (t - 0.75) / 0.25;
    return 1.0 - 0.05 * (1 - r) * (1 - r);
  }
}

// ─────────────────────────────────────────────────────────────

class _ArmarioPainter extends CustomPainter {
  final double doorOpen;
  final double itemsOpacity;

  static const _c1 = Color(0xFF9B6E4C);
  static const _c2 = Color(0xFF7B5233);
  static const _c3 = Color(0xFF5A3820);
  static const _c4 = Color(0xFF4A2E12);
  static const _cPanel = Color(0xFF8B5E3C);
  static const _cInt1 = Color(0xFF1E1008);
  static const _cInt2 = Color(0xFF0D0703);
  static const _cKnob = Color(0xFFC8A060);
  static const _cKnobL = Color(0xFFE0C080);

  const _ArmarioPainter({
    required this.doorOpen,
    required this.itemsOpacity,
  });

  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width;
    final h = sz.height;

    // Cuerpo exterior
    final bodyR = Rect.fromLTWH(w * .04, 0, w * .92, h * .95);//98
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyR, Radius.circular(w * .03)),
      Paint()
        ..shader = LinearGradient(
          colors: [_c1, _c2, _c3],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bodyR),
    );

    // Interior oscuro
    final intR = Rect.fromLTWH(w * .07, h * .012, w * .86, h * .888);
    canvas.drawRect(
      intR,
      Paint()
        ..shader = LinearGradient(
          colors: [_cInt1, _cInt2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(intR),
    );

    // Ribete interior
    canvas.drawRect(
      intR,
      Paint()
        ..color = _c4.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Techo
    final topR = Rect.fromLTWH(w * .01, 0, w * .98, h * .052);
    canvas.drawRRect(
      RRect.fromRectAndRadius(topR, Radius.circular(w * .03)),
      Paint()
        ..shader = LinearGradient(
          colors: [_c1, _c2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(topR),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topR, Radius.circular(w * .03)),
      Paint()
        ..color = _c4
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );

    // Base
    final baseR = Rect.fromLTWH(w * .01, h * .92, w * .98, h * .052);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseR, Radius.circular(w * .02)),
      Paint()..color = _c3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseR, Radius.circular(w * .02)),
      Paint()
        ..color = _c4
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );

    // Patas
    for (final lx in [w * .09, w * .83]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx, h * .952, w * .08, h * .048),
          Radius.circular(w * .025),
        ),
        Paint()..color = _c3,
      );
    }

    // Puertas
    // sc va de 1 (cerrado) a 0 (abierto)
    final sc = 1.0 - doorOpen;

    // Puerta izquierda: bisagra en el borde izquierdo (w*.07)
    // se aplana hacia la izquierda
    canvas.save();
    canvas.translate(w * .07, 0);
    canvas.scale(sc, 1.0);
    canvas.translate(-w * .07, 0);
    _paintDoor(canvas, sz, left: true);
    canvas.restore();

    // Puerta derecha: bisagra en el borde derecho (w*.93)
    // se aplana hacia la derecha — pivot en extremo derecho
    canvas.save();
    canvas.translate(w * .93, 0);
    canvas.scale(sc, 1.0);   // negativo: escala desde la derecha hacia la izquierda
    canvas.translate(-w * .93, 0);
    _paintDoor(canvas, sz, left: false);
    canvas.restore();
  }

  void _paintDoor(Canvas canvas, Size sz, {required bool left}) {
    final w = sz.width;
    final h = sz.height;
    final dx = left ? w * .07 : w * .495;
    final dw = w * .435;
    final doorR = Rect.fromLTWH(dx, h * .012, dw, h * .888);

    // Fondo puerta
    canvas.drawRect(
      doorR,
      Paint()
        ..shader = LinearGradient(
          colors: left
              ? [_c1, _c2, _c3]
              : [_c3, _c2, _c1], // invertido para puerta derecha
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(doorR),
    );

    // Canto de profundidad (siempre en el lado de la bisagra)
    // izq: canto a la izquierda | der: canto a la derecha
    canvas.drawRect(
      Rect.fromLTWH(
        left ? dx : dx + dw - w * .022,
        h * .012, w * .022, h * .888,
      ),
      Paint()..color = _c3.withValues(alpha: .45),
    );

    // Paneles
    _paintPanel(canvas, Rect.fromLTWH(dx + w * .025, h * .028, dw - w * .05, h * .40));
    _paintPanel(canvas, Rect.fromLTWH(dx + w * .025, h * .455, dw - w * .05, h * .41));

    // Tirador (siempre en el lado interior — centro del armario)
    // izq: lado derecho de la puerta | der: lado izquierdo de la puerta
    final knX = left ? dx + dw - w * .065 : dx + w * .018;
    final knY = h * .415;
    final knW = w * .04;
    final knH = h * .072;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(knX, knY, knW, knH),
        Radius.circular(knW * .5),
      ),
      Paint()..color = _cKnob,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(knX + knW * .2, knY + knH * .15, knW * .6, knH * .7),
        Radius.circular(knW * .3),
      ),
      Paint()..color = _cKnobL,
    );

    // Borde puerta
    canvas.drawRect(
      doorR,
      Paint()
        ..color = _c4
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Glare (reflejo en esquina superior interior)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left ? dx + w * .04 : dx + dw - w * .04 - dw * .28,
          h * .035,
          dw * .28,
          h * .20,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: .052),
    );
  }

  void _paintPanel(Canvas canvas, Rect outer) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(3)),
      Paint()..color = _c2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(outer.width * .09), const Radius.circular(2)),
      Paint()..color = _cPanel,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(3)),
      Paint()
        ..color = _c4.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
  }

  @override
  bool shouldRepaint(_ArmarioPainter old) =>
      old.doorOpen != doorOpen || old.itemsOpacity != itemsOpacity;
}