import 'package:flutter/material.dart';

import '../../../widgets/pet_avatar_rive.dart';

class BathPetOnFloorWidget extends StatelessWidget {
  final double petSize;
  final String tipoMascota;
  final double offsetX;
  final double offsetY;

  const BathPetOnFloorWidget({
    super.key,
    required this.petSize,
    required this.tipoMascota,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      offset: Offset(offsetX, offsetY),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PetAvatarRive(
            tipoMascota: tipoMascota,
            width: petSize,
            height: petSize,
          ),
          const SizedBox(height: 4),
          Container(
            width: petSize * 0.4,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
