import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/header_widget.dart';
import '../widgets/pet_avatar_rive.dart';
import '../widgets/paw_map_widget.dart';

class CurarScreen extends StatefulWidget {
  final String petName;
  final double healthPercent;

  const CurarScreen({
    super.key,
    this.petName = 'Copito',
    this.healthPercent = 0.75,
  });

  @override
  State<CurarScreen> createState() => _CurarScreenState();
}

class _CurarScreenState extends State<CurarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _heartAnim = CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final petName = mascota?.nombreMascota ?? widget.petName;
        final petType = (mascota?.tipoMascota ?? 'perro').toLowerCase();
        final healthPercent = mascota == null
            ? widget.healthPercent
            : ((mascota.nivelSalud.clamp(0, 100)) / 100);

        return Scaffold(
          backgroundColor: AppColors.verdeVeterinario,
          floatingActionButton: FloatingActionButton(
            onPressed: () => mostrarMapaHuella(context),
            backgroundColor: AppColors.verdeFondo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.pets, color: AppColors.azulPrincipal, size: 28),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity;
              if (velocity == null) return;
              if (velocity < -400) {
                context.go(AppRoutes.alimentar);
              } else if (velocity > 400) {
                context.go(AppRoutes.retos);
              }
            },
            child: Column(
              children: [
                _TopBar(
                  petName: petName,
                  healthPercent: healthPercent,
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: _VetScene(
                      heartAnim: _heartAnim,
                      petType: petType,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String petName;
  final double healthPercent;

  const _TopBar({required this.petName, required this.healthPercent});

  @override
  Widget build(BuildContext context) {
    final barraWidth = MediaQuery.of(context).size.width * 0.25;

    return HeaderWidget(
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 32,
                  color: AppColors.azulPrincipal,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Veterinaria',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.azulPrincipal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Hora de Curar a $petName',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Salud:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: barraWidth,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: healthPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rosa, AppColors.nivelSalud],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(healthPercent * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: healthPercent < 0.30
                      ? AppColors.estadoEnfermo
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VetScene extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;

  const _VetScene({
    required this.heartAnim,
    required this.petType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneWidth = constraints.maxWidth;
        final sceneHeight = constraints.maxHeight;
        final horizontalPadding = sceneWidth < 380 ? 18.0 : 32.0;
        final tableWidth = sceneWidth.clamp(260.0, 420.0) * 0.62;
        final petSize = sceneWidth < 380 ? 140.0 : 170.0;
        final sceneBlockBottom = (sceneHeight * 0.18).clamp(52.0, 110.0);
        final petTableSpacing = (sceneHeight * 0.03).clamp(8.0, 18.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 20,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MedicalPanel(),
                  const SizedBox(width: 12),
                  _EcgMonitor(animation: heartAnim),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: sceneBlockBottom,
              child: _CenteredVetStage(
                heartAnim: heartAnim,
                petType: petType,
                petSize: petSize,
                tableWidth: tableWidth,
                petTableSpacing: petTableSpacing,
                glowHeight: sceneHeight * 0.06,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CenteredVetStage extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;
  final double petSize;
  final double tableWidth;
  final double petTableSpacing;
  final double glowHeight;

  const _CenteredVetStage({
    required this.heartAnim,
    required this.petType,
    required this.petSize,
    required this.tableWidth,
    required this.petTableSpacing,
    required this.glowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: tableWidth,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 26,
              child: Container(
                width: tableWidth * 0.82,
                height: glowHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF9DC99D).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: petSize * 0.62),
              child: _ExamTable(width: tableWidth),
            ),
            Positioned(
              bottom: 26 + petTableSpacing,
              child: _BouncingPet(
                heartAnim: heartAnim,
                petType: petType,
                size: petSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalPanel extends StatelessWidget {
  const _MedicalPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FakeLine(width: 65, color: Color(0xFFD0D8D0)),
          SizedBox(height: 6),
          _FakeLine(width: 50, color: Color(0xFFD0D8D0)),
          SizedBox(height: 10),
          Row(
            children: [
              _ColorDot(color: Color(0xFFE8A0A0)),
              SizedBox(width: 6),
              _ColorDot(color: Color(0xFFA0A8E8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeLine extends StatelessWidget {
  final double width;
  final Color color;

  const _FakeLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EcgMonitor extends StatelessWidget {
  final Animation<double> animation;

  const _EcgMonitor({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF7A9A7A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => CustomPaint(
              painter: _EcgPainter(progress: animation.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;

  _EcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final tracePaint = Paint()
      ..color = const Color(0xFF9DC99D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final guidePaint = Paint()
      ..color = const Color(0xFF9DC99D).withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final mid = h * 0.55;
    final path = Path();
    final startX = w * 0.06;
    final endX = w * 0.94;
    final pulseWidth = endX - startX;
    final points = [
      Offset(startX, mid),
      Offset(startX + pulseWidth * 0.18, mid),
      Offset(startX + pulseWidth * 0.28, mid - h * 0.12),
      Offset(startX + pulseWidth * 0.36, mid + h * 0.28),
      Offset(startX + pulseWidth * 0.44, mid - h * 0.38),
      Offset(startX + pulseWidth * 0.52, mid),
      Offset(startX + pulseWidth * 0.76, mid),
      Offset(endX, mid),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, guidePaint);

    final metrics = path.computeMetrics().toList();
    final normalizedProgress = progress.clamp(0.0, 1.0);
    const pulseConfigs = <({double phase, double window})>[
      (phase: 0.0, window: 0.55),
      (phase: 0.80, window: 0.82),
    ];

    void drawTrace(double localProgress) {
      final clamped = localProgress.clamp(0.0, 1.0);
      for (final metric in metrics) {
        final traced = metric.extractPath(0, metric.length * clamped);
        canvas.drawPath(traced, tracePaint);
      }
    }

    for (final config in pulseConfigs) {
      final shifted = normalizedProgress - config.phase;
      final wrapped = shifted < 0 ? shifted + 1.0 : shifted;
      final localProgress = wrapped / config.window;
      if (localProgress >= 0 && localProgress <= 1) {
        drawTrace(localProgress);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BouncingPet extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;
  final double size;

  const _BouncingPet({
    required this.heartAnim,
    required this.petType,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: heartAnim,
      builder: (context, child) {
        final dy = sin(heartAnim.value * pi) * 4.0;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: child,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: PetAvatarRive(
          tipoMascota: petType,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class _ExamTable extends StatelessWidget {
  final double width;

  const _ExamTable({required this.width});

  @override
  Widget build(BuildContext context) {
    final legGap = (width * 0.54).clamp(88.0, 160.0);
    final legHeight = (width * 0.18).clamp(32.0, 54.0);
    final legWidth = (width * 0.06).clamp(12.0, 18.0);

    return Column(
      children: [
        Container(
          width: width,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E8D8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TableLeg(width: legWidth, height: legHeight),
            SizedBox(width: legGap),
            _TableLeg(width: legWidth, height: legHeight),
          ],
        ),
      ],
    );
  }
}

class _TableLeg extends StatelessWidget {
  final double width;
  final double height;

  const _TableLeg({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
