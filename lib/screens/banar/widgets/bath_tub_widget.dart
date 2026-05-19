import 'package:flutter/material.dart';

class BathTubWidget extends StatelessWidget {
  final bool petInTub;
  final bool canShowPet;
  final bool draggingBathTool;
  final bool showEscapeHint;
  final String? escapeHintText;
  final String? idleHintText;
  final VoidCallback onTapTub;
  final Widget Function(double tubWidth) buildTubLeg;
  final Widget Function(double tubWidth, {int delay}) buildDrip;
  final Widget Function(double tubWidth) buildPetInTub;

  const BathTubWidget({
    super.key,
    required this.petInTub,
    required this.canShowPet,
    required this.draggingBathTool,
    required this.showEscapeHint,
    required this.escapeHintText,
    this.idleHintText,
    required this.onTapTub,
    required this.buildTubLeg,
    required this.buildDrip,
    required this.buildPetInTub,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final expandedWidth = size.width * 0.78;
    final compactWidth = size.width * 0.56;
    final tubWidth = (petInTub ? expandedWidth : compactWidth)
        .clamp(220.0, size.width * 0.82)
        .toDouble();
    final tubHeight = tubWidth * 0.62;
    final tubTransitionDuration = Duration(milliseconds: petInTub ? 520 : 440);
    final tubSizeCurve = petInTub ? Curves.easeOutBack : Curves.easeInOutCubic;

    return Center(
      child: GestureDetector(
        onTap: draggingBathTool ? null : onTapTub,
        child: AnimatedContainer(
          duration: tubTransitionDuration,
          curve: tubSizeCurve,
          width: tubWidth,
          height: tubHeight * 1.45,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: tubWidth * 0.85,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: tubHeight * 0.02,
                left: tubWidth * 0.13,
                child: buildTubLeg(tubWidth),
              ),
              Positioned(
                bottom: tubHeight * 0.02,
                right: tubWidth * 0.13,
                child: buildTubLeg(tubWidth),
              ),
              Positioned(
                bottom: tubHeight * 0.09,
                child: Container(
                  width: tubWidth,
                  height: tubHeight * 0.88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(0xFFF5F5F7),
                        Color(0xFFE8E8ED),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                      bottomLeft: Radius.circular(110),
                      bottomRight: Radius.circular(110),
                    ),
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: tubHeight * 0.80,
                child: Container(
                  width: tubWidth * 1.04,
                  height: tubHeight * 0.22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFEEEEF3)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: tubHeight * 0.38,
                child: Container(
                  width: tubWidth * 0.55,
                  height: tubHeight * 0.10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (!petInTub && canShowPet)
                Positioned(
                  bottom: tubHeight * 0.34,
                  left: tubWidth * 0.11,
                  right: tubWidth * 0.11,
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final adaptiveFontSize = (constraints.maxWidth * 0.085)
                            .clamp(9.5, 15.0);
                        return Text(
                          'Toca la bañera para meter a la mascota a bañar.',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: adaptiveFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                            color: const Color(0xFF8EA7B5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (!petInTub && canShowPet && showEscapeHint && escapeHintText != null)
                Positioned(
                  bottom: tubHeight * 1.34,
                  left: tubWidth * 0.02,
                  right: tubWidth * 0.02,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFD3B3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        escapeHintText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7B5A4A),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: tubHeight * 0.10,
                child: Container(
                  width: tubWidth * 0.13,
                  height: tubHeight * 0.10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDE4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFCCCCD4),
                      width: 1,
                    ),
                  ),
                ),
              ),
              if (petInTub && canShowPet)
                Positioned(
                  bottom: tubHeight * 0.18,
                  left: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: buildPetInTub(tubWidth),
                  ),
                ),
              Positioned(
                bottom: tubHeight * 0.80,
                right: tubWidth * 0.11,
                child: Container(
                  width: tubWidth * 0.022,
                  height: tubHeight * 0.38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFDDDDE4),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: tubHeight * 1.18,
                right: tubWidth * 0.085,
                child: Container(
                  width: tubWidth * 0.11,
                  height: tubHeight * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFDDDDE4),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: tubHeight * 1.185,
                right: tubWidth * 0.074,
                child: Container(
                  width: tubWidth * 0.06,
                  height: tubWidth * 0.06,
                  decoration: const BoxDecoration(
                    color: Color(0xFF86DE63),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: tubWidth * 0.034,
                      height: tubWidth * 0.034,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6FCC4E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              if (!petInTub) ...[
                Positioned(
                  bottom: tubHeight * 1.10,
                  right: tubWidth * 0.115,
                  child: buildDrip(tubWidth, delay: 0),
                ),
                Positioned(
                  bottom: tubHeight * 0.98,
                  right: tubWidth * 0.115,
                  child: buildDrip(tubWidth, delay: 800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
