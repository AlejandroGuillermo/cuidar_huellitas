import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PetAvatarRive extends StatelessWidget {
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

  static const String _catAssetPath = 'assets/images/gato_vectorized.svg';

  String get _assetPath {
    final normalizedType = tipoMascota.toLowerCase().trim();
    switch (normalizedType) {
      case 'gato':
      case 'perro':
      default:
        return _catAssetPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        _assetPath,
        fit: BoxFit.contain,
        alignment: alignment,
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
      ),
    );
  }
}
