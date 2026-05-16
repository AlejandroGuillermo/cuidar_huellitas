import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BathSoapOverlayWidget extends StatelessWidget {
  const BathSoapOverlayWidget({
    super.key,
    required this.size,
    required this.progress,
    this.pawProgress = 0,
  });

  static const String _neckFoamAsset = 'assets/images/banar/espuma_cuello.svg';
  static const String _headEarRightAsset =
      'assets/images/banar/espuma_cabeza_ear_right.svg';
  static const String _headEarLeftAsset =
      'assets/images/banar/espuma_cabeza_ear_left.svg';
  static const String _headMidAsset =
      'assets/images/banar/espuma_cabeza_mid.svg';
  static const String _headMainAsset =
      'assets/images/banar/espuma_cabeza_main.svg';
  static const String _tailFoamAsset = 'assets/images/banar/espuma_cola.svg';
  static const String _feetLeftUpperAsset =
      'assets/images/banar/jabon_pies_left_upper.svg';
  static const String _feetUpperRightAsset =
      'assets/images/banar/jabon_pies_upper_right.svg';
  static const String _feetBottomBandAsset =
      'assets/images/banar/jabon_pies_bottom_band.svg';
  static const String _feetLowerMixAsset =
      'assets/images/banar/jabon_pies_lower_mix.svg';

  final double size;
  final double progress;
  final double pawProgress;

  double get _overallProgress => progress > pawProgress ? progress : pawProgress;

  @override
  Widget build(BuildContext context) {
    final overall = _overallProgress.clamp(0.0, 1.0);
    if (overall <= 0) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: size * -0.10,
              right: size * -0.13,
              top: size * -0.02,
              child: _HeadFoamOverlay(progress: overall),
            ),
            Positioned(
              left: size * -0.1,
              right: size * 0.04,
              top: size * -0.23,
              child: _TailFoamOverlay(progress: overall),
            ),
            Positioned(
              left: size * 0.32,
              right: size * 0.28,
              top: size * 0.53,
              child: _NeckFoamSvgOverlay(progress: overall),
            ),
            Positioned(
              left: size * 0.12,
              right: size * 0.10,
              top: size * 0.02,
              child: _FeetFoamSvgOverlay(progress: overall),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BathBubbleOverlayPainter(progress: overall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadFoamOverlay extends StatelessWidget {
  const _HeadFoamOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (413 / 487);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._headEarLeftAsset,
                width: width,
                height: height,
                progress: _segmentProgress(progress, 0.00, 0.28),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._headEarRightAsset,
                width: width,
                height: height,
                progress: _segmentProgress(progress, 0.18, 0.46),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._headMidAsset,
                width: width,
                height: height,
                progress: _segmentProgress(progress, 0.38, 0.70),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._headMainAsset,
                width: width,
                height: height,
                progress: _segmentProgress(progress, 0.60, 1.0),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TailFoamOverlay extends StatelessWidget {
  const _TailFoamOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (1236 / 977);

        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: progress.clamp(0.0, 1.0),
              child: SvgPicture.asset(
                BathSoapOverlayWidget._tailFoamAsset,
                width: width,
                height: height,
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NeckFoamSvgOverlay extends StatelessWidget {
  const _NeckFoamSvgOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * (273 / 482);

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: progress,
              child: SvgPicture.asset(
                BathSoapOverlayWidget._neckFoamAsset,
                width: constraints.maxWidth,
                height: height,
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeetFoamSvgOverlay extends StatelessWidget {
  const _FeetFoamSvgOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * (1236 / 977);

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Stack(
            children: [
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._feetLeftUpperAsset,
                width: constraints.maxWidth,
                height: height,
                progress: _segmentProgress(progress, 0.00, 0.28),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._feetUpperRightAsset,
                width: constraints.maxWidth,
                height: height,
                progress: _segmentProgress(progress, 0.22, 0.52),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._feetBottomBandAsset,
                width: constraints.maxWidth,
                height: height,
                progress: _segmentProgress(progress, 0.46, 0.76),
              ),
              _SoapStageSvg(
                asset: BathSoapOverlayWidget._feetLowerMixAsset,
                width: constraints.maxWidth,
                height: height,
                progress: _segmentProgress(progress, 0.68, 1.0),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoapStageSvg extends StatelessWidget {
  const _SoapStageSvg({
    required this.asset,
    required this.width,
    required this.height,
    required this.progress,
  });

  final String asset;
  final double width;
  final double height;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final reveal = progress.clamp(0.0, 1.0);
    if (reveal <= 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: reveal,
          child: SvgPicture.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

class _BathBubbleOverlayPainter extends CustomPainter {
  const _BathBubbleOverlayPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBlueBubble(
      canvas,
      center: Offset(size.width * 0.16, size.height * 0.53),
      radius: size.width * 0.050,
      progress: _segmentProgress(progress, 0.34, 0.52),
    );
    _paintGrayBubble(
      canvas,
      center: Offset(size.width * 0.84, size.height * 0.36),
      radius: size.width * 0.062,
      progress: _segmentProgress(progress, 0.40, 0.58),
    );
    _paintGrayBubble(
      canvas,
      center: Offset(size.width * 0.90, size.height * 0.81),
      radius: size.width * 0.052,
      progress: _segmentProgress(progress, 0.48, 0.66),
    );
    _paintBlueBubble(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.75),
      radius: size.width * 0.054,
      progress: _segmentProgress(progress, 0.54, 0.72),
    );
    _paintGrayBubble(
      canvas,
      center: Offset(size.width * 0.42, size.height * 0.17),
      radius: size.width * 0.038,
      progress: _segmentProgress(progress, 0.18, 0.34),
    );
  }

  double _segmentProgress(double overall, double start, double end) {
    if (overall <= start) return 0;
    if (overall >= end) return 1;
    return ((overall - start) / (end - start)).clamp(0.0, 1.0);
  }

  void _paintBlueBubble(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double progress,
  }) {
    if (progress <= 0) return;
    final outer = Paint()
      ..color = const Color(0xFFA1B4BA).withValues(alpha: 0.90 * progress);
    final inner = Paint()
      ..color = const Color(0xFFD2E5E9).withValues(alpha: 0.94 * progress);
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * progress);

    canvas.drawCircle(center.translate(radius * 0.10, radius * 0.10), radius, outer);
    canvas.drawCircle(center, radius, inner);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.30),
      radius * 0.22,
      highlight,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.18, center.dy + radius * 0.22),
      radius * 0.08,
      highlight,
    );
  }

  void _paintGrayBubble(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double progress,
  }) {
    if (progress <= 0) return;
    final outer = Paint()
      ..color = const Color(0xFFA1B4BA).withValues(alpha: 0.92 * progress);
    final inner = Paint()
      ..color = const Color(0xFFD6D7DC).withValues(alpha: 0.95 * progress);
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.90 * progress);

    canvas.drawCircle(center.translate(radius * 0.08, radius * 0.10), radius, outer);
    canvas.drawCircle(center, radius, inner);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.26, center.dy - radius * 0.28),
      radius * 0.19,
      highlight,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.14, center.dy + radius * 0.24),
      radius * 0.07,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BathBubbleOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

double _segmentProgress(double overall, double start, double end) {
  if (overall <= start) return 0;
  if (overall >= end) return 1;
  return ((overall - start) / (end - start)).clamp(0.0, 1.0);
}
