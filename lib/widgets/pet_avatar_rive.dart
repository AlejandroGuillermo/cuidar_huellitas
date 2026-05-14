import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PetAvatarRive extends StatefulWidget {
  const PetAvatarRive({
    super.key,
    required this.tipoMascota,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String tipoMascota;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  State<PetAvatarRive> createState() => _PetAvatarRiveState();
}

class _PetAvatarRiveState extends State<PetAvatarRive>
    with TickerProviderStateMixin {
  static const String _catAssetPath = 'assets/images/gato_vectorized.svg';
  static const String _dogAssetPath = 'assets/images/perro_vectorized.svg';
  static const String _catBodyAssetPath =
      'assets/images/gato_vectorized_body.svg';
  static const String _catTailAssetPath =
      'assets/images/gato_vectorized_tail.svg';
  static const String _catLeftEyeAssetPath =
      'assets/images/gato_vectorized_eye_left.svg';
  static const String _catRightEyeAssetPath =
      'assets/images/gato_vectorized_eye_right.svg';
  static const String _catLeftEarAssetPath =
      'assets/images/gato_vectorized_ear_left.svg';
  static const String _catRightEarAssetPath =
      'assets/images/gato_vectorized_ear_right.svg';

  final math.Random _random = math.Random();

  late final AnimationController _tailController;
  late final AnimationController _breathController;
  late final AnimationController _eyesController;
  late final AnimationController _earsController;

  Offset _currentEyeOffset = Offset.zero;
  Offset _targetEyeOffset = Offset.zero;
  Timer? _eyeTimer;
  double _currentLeftEarAngle = 0;
  double _targetLeftEarAngle = 0;
  double _currentRightEarAngle = 0;
  double _targetRightEarAngle = 0;
  Timer? _earTimer;

  String get _assetPath {
    final normalizedType = widget.tipoMascota.toLowerCase().trim();
    switch (normalizedType) {
      case 'gato':
      case 'cat':
        return _catAssetPath;
      case 'perro':
      case 'dog':
        return _dogAssetPath;
      default:
        return _catAssetPath;
    }
  }

  bool get _isCat {
    final normalizedType = widget.tipoMascota.toLowerCase().trim();
    return normalizedType == 'gato' || normalizedType == 'cat';
  }

  @override
  void initState() {
    super.initState();
    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
      lowerBound: -1,
      upperBound: 1,
    )..repeat(reverse: true);
    _eyesController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 550),
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    _earsController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    _scheduleNextLook();
    _scheduleNextEarTwitch();
  }

  @override
  void dispose() {
    _eyeTimer?.cancel();
    _earTimer?.cancel();
    _tailController.dispose();
    _breathController.dispose();
    _eyesController.dispose();
    _earsController.dispose();
    super.dispose();
  }

  void _scheduleNextLook() {
    _eyeTimer?.cancel();
    final waitMs = 1800 + _random.nextInt(2400);
    _eyeTimer = Timer(Duration(milliseconds: waitMs), _startEyeMove);
  }

  void _startEyeMove() {
    if (!mounted || !_isCat) return;

    _currentEyeOffset = _eyeOffset;
    const candidates = <Offset>[
      Offset.zero,
      Offset(-2.8, 0),
      Offset(2.8, 0),
      Offset(0, -1.8),
      Offset(-1.6, -1.2),
      Offset(1.6, -1.2),
      Offset(-2.0, 1.0),
      Offset(2.0, 1.0),
    ];
    _targetEyeOffset = candidates[_random.nextInt(candidates.length)];
    _eyesController
      ..duration = Duration(milliseconds: 420 + _random.nextInt(260))
      ..forward(from: 0).whenComplete(_scheduleNextLook);
  }

  void _scheduleNextEarTwitch() {
    _earTimer?.cancel();
    final waitMs = 2600 + _random.nextInt(3200);
    _earTimer = Timer(Duration(milliseconds: waitMs), _startEarTwitch);
  }

  void _startEarTwitch() {
    if (!mounted || !_isCat) return;

    _currentLeftEarAngle = _leftEarAngle;
    _currentRightEarAngle = _rightEarAngle;

    final mode = _random.nextInt(4);
    switch (mode) {
      case 0:
        _targetLeftEarAngle = -0.10;
        _targetRightEarAngle = 0;
        break;
      case 1:
        _targetLeftEarAngle = 0;
        _targetRightEarAngle = 0.10;
        break;
      case 2:
        _targetLeftEarAngle = -0.06;
        _targetRightEarAngle = 0.06;
        break;
      default:
        _targetLeftEarAngle = 0;
        _targetRightEarAngle = 0;
    }

    _earsController
      ..duration = Duration(milliseconds: 180 + _random.nextInt(140))
      ..forward(from: 0).whenComplete(() async {
        if (!mounted) return;
        await Future<void>.delayed(
          Duration(milliseconds: 120 + _random.nextInt(140)),
        );
        if (!mounted) return;
        _currentLeftEarAngle = _leftEarAngle;
        _currentRightEarAngle = _rightEarAngle;
        _targetLeftEarAngle = 0;
        _targetRightEarAngle = 0;
        await _earsController.forward(from: 0);
        _scheduleNextEarTwitch();
      });
  }

  Offset get _eyeOffset =>
      Offset.lerp(_currentEyeOffset, _targetEyeOffset, _eyesController.value) ??
      Offset.zero;

  double get _leftEarAngle =>
      lerpDouble(
        _currentLeftEarAngle,
        _targetLeftEarAngle,
        _earsController.value,
      ) ??
      0;

  double get _rightEarAngle =>
      lerpDouble(
        _currentRightEarAngle,
        _targetRightEarAngle,
        _earsController.value,
      ) ??
      0;

  double get _headTurnAngle => (_eyeOffset.dx / 10) * 0.05;

  Offset get _headTurnOffset =>
      Offset(_eyeOffset.dx * 0.45, _eyeOffset.dy * 0.3);

  double get _tailAngle {
    return 0;
  }

  double get _breathScale => 1 + (_breathController.value * 0.012);

  Widget _buildSvgLayer(String assetPath) {
    return SvgPicture.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: widget.alignment,
      semanticsLabel: 'Mascota vectorizada',
      placeholderBuilder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7ED),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Center(
          child: Icon(Icons.pets_rounded, color: Color(0xFF5B6C95)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: !_isCat
          ? _buildSvgLayer(_assetPath)
          : AnimatedBuilder(
              animation: Listenable.merge([_tailController, _breathController]),
              builder: (context, child) {
                return Transform.scale(scale: _breathScale, child: child);
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: _headTurnOffset,
                    child: Transform.rotate(
                      angle: _headTurnAngle,
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          _buildSvgLayer(_catBodyAssetPath),
                          Transform.rotate(
                            angle: _leftEarAngle,
                            alignment: const Alignment(-0.28, -0.43),
                            child: _buildSvgLayer(_catLeftEarAssetPath),
                          ),
                          Transform.rotate(
                            angle: _rightEarAngle,
                            alignment: const Alignment(0.28, -0.43),
                            child: _buildSvgLayer(_catRightEarAssetPath),
                          ),
                          Transform.translate(
                            offset: _eyeOffset,
                            child: _buildSvgLayer(_catRightEyeAssetPath),
                          ),
                          Transform.translate(
                            offset: _eyeOffset,
                            child: _buildSvgLayer(_catLeftEyeAssetPath),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _tailAngle,
                    alignment: const Alignment(0.32, 0.14),
                    child: _buildSvgLayer(_catTailAssetPath),
                  ),
                ],
              ),
            ),
    );
  }
}
