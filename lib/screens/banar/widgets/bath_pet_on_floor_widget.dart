import 'package:flutter/material.dart';

import '../../../widgets/pet_avatar_rive.dart';

class BathPetOnFloorWidget extends StatelessWidget {
  final double petSize;
  final String tipoMascota;

  const BathPetOnFloorWidget({
    super.key,
    required this.petSize,
    required this.tipoMascota,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
