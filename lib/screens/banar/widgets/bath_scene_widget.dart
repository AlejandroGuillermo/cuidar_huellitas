import 'package:flutter/material.dart';

class BathSceneWidget extends StatelessWidget {
  final double floorHeight;
  final double petFloorBottom;
  final bool showProgressPanel;
  final Widget progressPanel;
  final bool showToolBar;
  final double toolBarLeft;
  final double toolBarAboveTubBottom;
  final bool petInTub;
  final Widget toolBar;
  final bool canShowPet;
  final Widget petOnFloor;
  final Duration transitionDuration;
  final Curve positionCurve;
  final double tubBottom;
  final Widget tub;
  final bool showBathStatus;
  final double bathStatusBottom;
  final Widget bathStatus;
  final Widget wall;
  final Widget floor;
  final Widget mirror;
  final double sizeHeight;
  final double sizeWidth;

  const BathSceneWidget({
    super.key,
    required this.floorHeight,
    required this.petFloorBottom,
    required this.showProgressPanel,
    required this.progressPanel,
    required this.showToolBar,
    required this.toolBarLeft,
    required this.toolBarAboveTubBottom,
    required this.petInTub,
    required this.toolBar,
    required this.canShowPet,
    required this.petOnFloor,
    required this.transitionDuration,
    required this.positionCurve,
    required this.tubBottom,
    required this.tub,
    required this.showBathStatus,
    required this.bathStatusBottom,
    required this.bathStatus,
    required this.wall,
    required this.floor,
    required this.mirror,
    required this.sizeHeight,
    required this.sizeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: wall),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: floorHeight,
          child: floor,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: floorHeight - 6,
          height: 12,
          child: Container(color: const Color(0xFF8FB3C2)),
        ),
        Positioned(
          top: sizeHeight * 0.08,
          left: sizeWidth * 0.08,
          child: mirror,
        ),
        if (showProgressPanel)
          Positioned(top: sizeHeight * 0.09, right: 16, child: progressPanel),
        if (showToolBar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: toolBarLeft,
            bottom: toolBarAboveTubBottom,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: petInTub ? 1 : 0.92,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: petInTub ? 1 : 0,
                child: toolBar,
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: petFloorBottom,
          child: IgnorePointer(
            ignoring: petInTub,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              opacity: petInTub ? 0 : 1,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: petInTub ? const Offset(0, 0.12) : Offset.zero,
                child: canShowPet ? petOnFloor : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: transitionDuration,
          curve: positionCurve,
          left: 0,
          right: 0,
          bottom: tubBottom,
          child: tub,
        ),
        if (showBathStatus)
          Positioned(
            left: 24,
            right: 24,
            bottom: bathStatusBottom,
            child: bathStatus,
          ),
      ],
    );
  }
}
