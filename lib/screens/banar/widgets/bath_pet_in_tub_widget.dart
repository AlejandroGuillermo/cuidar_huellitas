import 'package:flutter/material.dart';

import 'bath_soap_overlay_widget.dart';
import '../../../widgets/pet_avatar_rive.dart';

class BathPetInTubWidget<T extends Object> extends StatelessWidget {
  final double petSize;
  final bool Function(T? tool) canAcceptTool;
  final void Function(DragTargetDetails<T> details) onMoveTool;
  final void Function(DragTargetDetails<T> details) onAcceptTool;
  final bool isHoveringTool;
  final GestureDragUpdateCallback onPanUpdate;
  final Duration slideDuration;
  final Offset slideOffset;
  final String tipoMascota;
  final double soapOverlayProgress;
  final double pawSoapOverlayProgress;

  const BathPetInTubWidget({
    super.key,
    required this.petSize,
    required this.canAcceptTool,
    required this.onMoveTool,
    required this.onAcceptTool,
    required this.isHoveringTool,
    required this.onPanUpdate,
    required this.slideDuration,
    required this.slideOffset,
    required this.tipoMascota,
    required this.soapOverlayProgress,
    required this.pawSoapOverlayProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DragTarget<T>(
        onWillAcceptWithDetails: (details) => canAcceptTool(details.data),
        onMove: onMoveTool,
        onAcceptWithDetails: onAcceptTool,
        builder: (context, candidates, rejected) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: onPanUpdate,
            child: AnimatedSlide(
              duration: slideDuration,
              curve: Curves.easeInOut,
              offset: slideOffset,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: isHoveringTool ? 1.04 : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: PetAvatarRive(
                        tipoMascota: tipoMascota,
                        width: petSize,
                        height: petSize,
                      ),
                    ),
                    if (soapOverlayProgress > 0)
                      IgnorePointer(
                        child: BathSoapOverlayWidget(
                          size: petSize,
                          progress: soapOverlayProgress,
                          pawProgress: pawSoapOverlayProgress,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
